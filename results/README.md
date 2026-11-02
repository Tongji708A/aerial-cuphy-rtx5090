# Results

| File | Content |
|---|---|
| `gate_a_summary.tsv` | 14 unit-test binaries, PASS/FAIL, gtest counts |
| `gate_b_summary.tsv` | 208 channel runs (channel, mode, vector, result) from `score_logs.py` |
| `gate_b_latency.csv` | per-run latency in µs for PDSCH / PDCCH / PUSCH |
| `gate_b_score.txt` | `score_logs.py` console output |
| `logs/gate-a/` | build tail, smoke, per-test logs, sanitizer diagnostics, first-run failures |
| `logs/gate-b/run/` | the 208 scored example logs (each ≤ a few KB) |
| `logs/gate-b/40_summary.original.tsv` | the run's own summary (first-pass grep, then rescored) |
| `logs/bench/` | `cubb_gpu_test_bench` attempts showing `CUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY` |

Test vectors are not included (≈21 GB, generated output of NVIDIA tooling). Regenerate with `scripts/06_gen_tv.sh`.
Timestamps inside logs are UTC.
