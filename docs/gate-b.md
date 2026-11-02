# Gate B — L1 channels vs. 5GModel test vectors

**Result: 208/208 PASS.** Summary: [`results/gate_b_summary.tsv`](../results/gate_b_summary.tsv) ·
latencies: [`results/gate_b_latency.csv`](../results/gate_b_latency.csv) · logs: [`results/logs/gate-b/run/`](../results/logs/gate-b/run/).

## Pipeline

1. Full SDK build for sm_120 (921/921 steps, ~85 min with `JOBS=6` / 16 GB RAM) — `scripts/02_build_sm120.sh`.
2. Derived image with MATLAB Runtime dependencies — `docker/Dockerfile`.
3. MATLAB Runtime R2023a U1 silent install, mounted at `/usr/local/MATLAB` — `scripts/05_install_mcr.sh`.
4. Test vectors via `aerial_mcore` `example_5GModel_regression.py <channel>` with `REGRESSION_MODE=2` (compact) — `scripts/06_gen_tv.sh`.
5. First `CAP=16` vectors per channel through the cuPHY example apps, both modes — `scripts/07_run_channels.sh`.
6. Scoring — `scripts/score_logs.py`.

### Generated vectors (compact set)

| Channel | ≈ vectors |
|---|---|
| SSB | 49 |
| PDCCH | 95 |
| PDSCH | 490 |
| PUSCH | 677 (non-HARQ; PUSCH generation was OOM-killed partway with 16 GB RAM) |
| PRACH | 66 |
| PUCCH F0/F1/F2/F3 | 102 / 175 / 118 / 148 |
| CSI-RS | 103 |

Total ≈ 21 GB, ~4,100 files. **Not included in this repo** — regenerate them.

## Scoring rules

The first pass grepped for `Test PASS` everywhere and reported 144/208: PUSCH and PUCCH apps never print that string.
`score_logs.py` uses each app's own reference comparison instead:

| Channel | PASS when |
|---|---|
| SSB, PDCCH, PRACH, CSI-RS | `Test PASS` |
| PDSCH | every `Found N mismatched` has N = 0 |
| PUSCH | every `MismatchedCRC CBs/TBs` = 0, BLER = 0, no `FATAL` |
| PUCCH | every `found N mismatches` has N = 0, no `FATAL` |

Running it on the published logs reproduces 208/208:

```
$ python3 scripts/score_logs.py results/logs/gate-b/run
```

See [`results/gate_b_score.txt`](../results/gate_b_score.txt) for the output.

## Latency (single cell, this run)

| Channel | Metric | Mode | n | min | median | max (µs) |
|---|---|---|---|---|---|---|
| PDSCH | DL pipeline | g0 streams | 16 | 49.2 | 59.7 | 72.0 |
| PDSCH | DL pipeline | g1 graphs | 16 | 25.9 | 35.6 | 44.1 |
| PDCCH | GPU-run only | m0 | 16 | 14.4 | 14.6 | 15.5 |
| PDCCH | GPU-run only | m1 | 16 | 12.9 | 13.1 | 13.9 |
| PUSCH | GPU total (CUDA event) | m0 | 16 | 135.7 | 148.2 | 204.4 |
| PUSCH | GPU total (CUDA event) | m1 | 16 | 144.1 | 155.4 | 203.9 |

These are example-app timings (allocations/setup excluded as the apps note), averaged over a few iterations, on one cell.
They are **not** slot-budget or capacity numbers — that needs `cubb_gpu_test_bench`, which does not run on this GPU (below).

## cubb_gpu_test_bench (multi-cell)

| Attempt | Flags | Result |
|---|---|---|
| 1 | `--D --U --P --Q --X --B --G --g` | `CUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY` in `cuCtxCreate` |
| 2 | no context flags | `nCtxts = 0, no subcontexts are defined` |
| 3 | `--D --U` only; `-u 3 --D --U`; no `-n` (green contexts), no `--M` | same `UNSUPPORTED_EXEC_AFFINITY` |

Logs: [`results/logs/bench/`](../results/logs/bench/). This is a platform limitation (execution-affinity sub-contexts on this GPU/driver/VM combination), not a missing build artefact.

## cuphycontroller + testMAC

`cuphycontroller_scf` and `test_mac` build. They do not start without a fronthaul NIC: `PhyDriverCtx` always constructs `FhProxy` and calls `registerNic`, and the shipped configs expect `nics: - nic: '<PCI BDF>'` with `standalone: 0`. Needs a ConnectX-7 / BlueField-3 class NIC with DOCA/DPDK.
