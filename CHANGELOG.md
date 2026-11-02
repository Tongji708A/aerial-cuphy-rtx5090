# Changelog

All notable changes to this project are documented here. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] — 2026-11-02

### Added
- Build of Aerial 26.1.2 for `sm_120` (CUDA 13.1, driver 590.48.01) on RTX 5090 in a PCIe-passthrough VM.
- Patches 0008–0011 (cuPHY CRC legacy-launch fix + three test fixes); Gate A 14/14.
- Test-vector pipeline with MATLAB Runtime R2023a (derived image Dockerfile, symlink-preserving unzip).
- Gate B: 7 L1 channels, 208/208 PASS; `score_logs.py` and published summary / latency / logs.

### Known issues
- `cubb_gpu_test_bench` multi-cell: `CUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY` on RTX 5090.
- `cuphycontroller` / `testMAC` need a CX7/BF3 fronthaul NIC; no RU end-to-end yet.
