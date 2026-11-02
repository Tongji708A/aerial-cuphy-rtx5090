# Environment

## Tested stack

| Item | Value |
|---|---|
| Host | Lenovo WR5220 G5, 2U dual-socket x86_64, Proxmox VE |
| GPU passthrough | Full PCIe passthrough of one RTX 5090 to a KVM guest (vfio-pci) |
| Guest | Ubuntu 24.04.4 LTS, kernel 6.8.0, 8 vCPU, 16 GB RAM |
| Driver | NVIDIA 590.48.01 (matches the Aerial 26-1 software manifest) |
| Docker | Docker Engine + NVIDIA Container Toolkit (`--gpus all`) |
| Image | `nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb` (pull with your own NGC key) |
| CUDA in image | 13.1 (`cuda_13.1.r13.1`) |
| Source | `NVIDIA/aerial-cuda-accelerated-ran` tag `26.1.2`, commit `efe0d8c73e3ecc83a36ccdfec631d8f34a2e980f` |
| MATLAB Runtime | R2023a Update 1 (glnxa64), installed outside the image and bind-mounted |

The Aerial 26-1 manifest qualifies Grace Hopper / DGX-class platforms, not x86 + GeForce. CUDA ≥ 12.8 is the minimum for CC 12.0; 26.1.x `build_aerial_sdk.sh` already includes `120` in its default arch list, we pass `--cuda-archs 120` explicitly to build only what we run.

## Disk / RAM budget

| Item | Size |
|---|---|
| Aerial image | ~45 GB on disk (≈16 GB compressed layers) |
| Source + `build.sm120` | ~25–30 GB |
| MATLAB Runtime | ~4 GB installed |
| Test vectors (compact) | ~21 GB |
| RAM | 16 GB works with `JOBS=6`; TV generation for PUSCH can be OOM-killed |

## Container mounts used by the scripts

| Host | Container |
|---|---|
| `$AERIAL_SRC` | `/opt/aerial/src` (`cuBB_SDK`) |
| `$WORK_DIR` | `/work` |
| `$MATLAB_DIR` | `/usr/local/MATLAB` |
