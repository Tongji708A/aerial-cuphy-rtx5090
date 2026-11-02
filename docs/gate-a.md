# Gate A — cuPHY unit tests on sm_120

**Result: 14/14 PASS** (CUDA 13.1, driver 590.48.01, RTX 5090). Logs: [`results/logs/gate-a/`](../results/logs/gate-a/).

## Build

`build_aerial_sdk.sh --build_dir build.sm120 --toolchain native --preset perf --cuda-archs 120`, `JOBS=6`.
`cuobjdump --list-elf libcuphy.so` shows **65 × sm_120** ELF images (no PTX-JIT fallback needed).

## First run (26.1.2 without patches 0008–0011): 11 PASS / 3 FAIL

| Test | First run | Root cause | sm_120-specific? | Fix | After |
|---|---|---|---|---|---|
| `test_fill` `Fill.IndexGroup` | FAIL | Self-contradictory upstream test: a `CUPHY_BIT` subset starting at bit 16 violates `tensor_ref::subset()`'s 32-bit word alignment rule (throws), and `cuphy_i::tensor_fill()` has no `CUPHY_BIT` branch (`UNSUPPORTED_TYPE`). Cannot pass on any GPU. | No | **0009** asserts both contracts (`EXPECT_THROW`); the other 9 types still fill and verify | PASS 2/2 |
| `test_tile` `Tile.InternalError` | rc=139 segfault, remaining tests never ran | Test deliberately launches on a **destroyed** `cudaStream_t` — undefined behaviour. CUDA 13.1 + r590 dereferences it and crashes instead of returning an error. | No (CUDA/driver behaviour) | **0010** `GTEST_SKIP` unless `CUPHY_TEST_UB_STREAM=1` (opt-in reproduces rc=139); remaining tests are clean under `compute-sanitizer memcheck` | PASS 5 + 1 skip |
| `crcTest` `CRC_GPU_UPLINK_PUSCH.24B_24A` | FAIL (CB6/7 CRC ≠ 0, TB data mismatched) | **Library bug.** Legacy `crc::launch()` (`cuphyCRCDecode`) never initialises `desc.schUserIdxs[]`; the descriptor sits in uninitialised `cudaHostAlloc` memory and the kernel reads `schUserIdxs[blockIdx.y]`, so every TB uses TB0's parameters. Production `cuphySetupPuschRxCrcDecode` sets it and is unaffected. | No (uninitialised memory) | **0008** identity-map `schUserIdxs`; **0011** `CRCTest.UplinkPuschWithTiming` had the bug baked in as the expected value (`EXPECT_EQ(result,0)`), now expects 1 | PASS 9/9, memcheck 0 errors |

Failure logs from the first run: [`results/logs/gate-a/v2_failed/`](../results/logs/gate-a/v2_failed/) (the 20 MB crcTest log is trimmed).

Cosmetic, not patched: crcTest's timed path prints `inf us` because `NRUNS=0`.

## Reproduce

```bash
scripts/01_apply_patches.sh
TARGETS="cuphy test_fill test_tile crcTest" scripts/02_build_sm120.sh   # incremental, <1 min after a full build
scripts/03_gate_a_smoke.sh
```

## GPU telemetry during smoke (5 s samples)

Peak ~35 °C, SM 2527 MHz, ~69 W, ~718 MiB VRAM ([`v2_nvidia_smi.csv`](../results/logs/gate-a/v2_nvidia_smi.csv)).
