# Troubleshooting

## Gate A failures on an unpatched 26.1.2 tree

`test_fill`, `test_tile` (segfault rc=139) and `crcTest` fail on CUDA 13.1 / r590. None is sm_120-specific — apply `patches/validated/0008-0011`. Details in [gate-a.md](gate-a.md).

## MATLAB Runtime installer fails after `unzip`

The R2023a zip contains symlinks; Info-ZIP `unzip` in the container drops/flattens them and the installer or runtime then cannot find its libraries. Use `scripts/unz.py`, which recreates symlinks from the zip's mode bits.

## MATLAB Runtime / aerial_mcore: `libnss3.so: cannot open shared object file`

The Aerial image lacks several desktop libraries the MATLAB Runtime JVM loads (libnss3, libnspr4, X11/GTK bits). Build the derived image: `scripts/04_build_mcr_image.sh` (`docker/Dockerfile`). Do not push it to a public registry.

## `Test PASS` missing for PUSCH / PUCCH

Those apps do not print it. Use `scripts/score_logs.py` (checks CRC/BLER/mismatch counters).

## PUSCH test-vector generation killed

With 16 GB RAM the MATLAB parallel pool can be OOM-killed during PUSCH generation. The vectors written before the kill are valid. Reduce the parpool size or add RAM/swap.

## `CUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY` from cubb_gpu_test_bench

Known limitation on RTX 5090 (driver 590.48.01, VM passthrough). Single-channel examples work; multi-cell bench does not. See [gate-b.md](gate-b.md#cubb_gpu_test_bench-multi-cell).

## Host storage hangs during huge image pulls

The Aerial image is ~45 GB. Lesson learned: **avoid huge image pulls on hosts with fragile storage** (e.g. a RAID controller or SSD that has already shown resets/timeouts under sustained write load). Pull on a different machine and stream it over the LAN with `docker save | ssh <target> docker load`, keep build output off the fragile volume where possible, and watch the host's kernel log during the transfer.

## cuphycontroller exits at NIC registration

Expected without a fronthaul NIC (ConnectX-7 / BlueField-3). See [gate-b.md](gate-b.md#cuphycontroller--testmac).
