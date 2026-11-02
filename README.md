<div align="center">

# Aerial cuPHY on RTX 5090 (sm_120)

**NVIDIA Aerial CUDA-Accelerated RAN 26.1 cuPHY L1, built for Blackwell `sm_120` and validated on a consumer GeForce RTX 5090.**

[![CUDA](https://img.shields.io/badge/CUDA-13.1-76B900?logo=nvidia&logoColor=white)](#hardware--software-matrix)
[![Driver](https://img.shields.io/badge/driver-590.48.01-76B900)](#hardware--software-matrix)
[![GPU](https://img.shields.io/badge/GPU-RTX%205090%20(sm__120)-black?logo=nvidia)](#hardware--software-matrix)
[![Aerial](https://img.shields.io/badge/Aerial-26.1.2-blue)](https://github.com/NVIDIA/aerial-cuda-accelerated-ran)
[![Status](https://img.shields.io/badge/status-L1%20validated-brightgreen)](#tldr)
[![Fronthaul](https://img.shields.io/badge/fronthaul%20%2F%20RU-in%20progress-orange)](#known-limitations)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

English | [简体中文](README.zh-CN.md)

</div>

> **Unofficial community project.** Not affiliated with, sponsored by, or endorsed by NVIDIA.
> RTX 5090 / x86 is **not** a qualified Aerial platform. See [Disclaimer](#acknowledgements--disclaimer).

## TL;DR

OpenLab has completed Aerial cuPHY L1 adaptation and validation on a consumer RTX 5090; full fronthaul and RU integration is in progress.

| Gate | What | Result |
|---|---|---|
| **Build** | Aerial 26.1.2, `--cuda-archs 120`, full SDK (921/921 ninja steps) | ✅ `libcuphy.so` carries 65 × `sm_120` cubins |
| **Gate A** | 14 cuPHY unit-test binaries | ✅ **14/14 PASS** (with [patches 0008–0011](patches/validated/)) |
| **Gate B** | Per-channel cuPHY examples vs. MATLAB-generated test vectors, streams + graphs | ✅ **208/208 PASS** |

<details open><summary><b>Gate B per channel</b> (first 16 vectors per channel × 2 modes: `-m 0/1`, PDSCH graphs flag `g0`=streams / `g1`=graphs; CSI-RS 1 mode)</summary>

| Channel | Example binary | Pass | Single-cell latency (this run) |
|---|---|---|---|
| SSB | `testSS` | 32/32 | — |
| PDSCH | `cuphy_ex_pdsch_tx` | 32/32 | DL pipeline: streams **~60 µs** median (49–72), graphs **~36 µs** (26–44) |
| PDCCH | `cuphy_ex_pdcch_tx_multi_cell` | 32/32 | GPU-run only: m0 **~14.6 µs** (14.4–15.5), m1 **~13.1 µs** (12.9–13.9) |
| PUSCH | `cuphy_ex_pusch_rx_multi_pipe` | 32/32 | GPU total (CUDA event): m0 **~148 µs** (136–204), m1 **~155 µs** (144–204); BLER 0, 0 CRC mismatches |
| PUCCH F0–F3 | `cuphy_ex_pucch_rx_pipeline` | 32/32 | 0 UCI mismatches |
| PRACH | `prach_receiver_multi_cell` | 32/32 | — |
| CSI-RS | `cuphy_ex_csirs_tx_multi_cell` | 16/16 | — |
| **Total** | | **208/208** | |

Raw numbers: [`results/gate_b_summary.tsv`](results/gate_b_summary.tsv), [`results/gate_b_latency.csv`](results/gate_b_latency.csv).
Latencies are per-example timings from the cuPHY sample apps on one cell, **not** a multi-cell slot-budget measurement (see [limitations](#known-limitations)).
</details>

## Hardware / software matrix

| Layer | Tested |
|---|---|
| Host | Lenovo WR5220 G5 (2U dual-socket x86_64 server), Proxmox VE hypervisor |
| VM | KVM guest with full PCIe GPU passthrough; 8 vCPU, 16 GB RAM |
| Guest OS | Ubuntu 24.04.4 LTS, kernel 6.8.0 |
| GPU | NVIDIA GeForce RTX 5090, 32 GB, compute capability 12.0 (`sm_120`) |
| Driver | 590.48.01 |
| Container | `nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb` (Ubuntu 22.04 inside, ~45 GB on disk) |
| CUDA | 13.1 (`nvcc cuda_13.1.r13.1`) |
| Aerial source | [`NVIDIA/aerial-cuda-accelerated-ran`](https://github.com/NVIDIA/aerial-cuda-accelerated-ran) tag `26.1.2` (`efe0d8c7`) |
| Test vectors | `aerial_mcore` + MATLAB Runtime R2023a Update 1, `REGRESSION_MODE=2` (compact) |
| Fronthaul NIC | none (see limitations) |

More detail: [docs/environment.md](docs/environment.md).

## Quickstart

> You need: an RTX 5090 (or other CC 12.0 GPU) with driver ≥ 590.48.01, Docker + NVIDIA Container Toolkit,
> ~120 GB free disk (image 45 GB, source+build ~30 GB, test vectors ~21 GB), an **NGC API key of your own**,
> and a MATLAB Runtime R2023a Update 1 download you accept the MathWorks license for.

```bash
git clone <this-repo> aerial-5090 && cd aerial-5090
export WORK_DIR=$HOME/aerial_work            # see scripts/env.sh for all knobs

# 1. Pull the Aerial container with YOUR NGC key (not provided here)
docker login nvcr.io                         # user: $oauthtoken  password: <NGC API key>
docker pull nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb

# 2. Source + OpenLab patches
scripts/00_fetch_source.sh                   # clones NVIDIA/aerial-cuda-accelerated-ran @ 26.1.2 (+ LFS)
scripts/01_apply_patches.sh                  # applies patches/validated/0008-0011

# 3. Build for sm_120 and run Gate A
scripts/02_build_sm120.sh                    # full build; TARGETS="cuphy crcTest ..." for a quick one
scripts/03_gate_a_smoke.sh                   # expect 14/14 PASS

# 4. Test vectors (MATLAB Runtime R2023a)
scripts/04_build_mcr_image.sh                # docker/Dockerfile: base image + libnss3 & friends
cp ~/Downloads/MATLAB_Runtime_R2023a_Update_1_glnxa64.zip $WORK_DIR/mcr/
scripts/05_install_mcr.sh
scripts/06_gen_tv.sh                         # ~21 GB, several hours

# 5. Gate B: run the channels and score
CAP=16 scripts/07_run_channels.sh            # prints per-channel PASS counts + latency stats
scripts/08_bench_attempt.sh                  # optional: reproduces the multi-cell limitation
```

Re-score our published logs without a GPU: `python3 scripts/score_logs.py results/logs/gate-b/run`.

## Repository layout

```
docs/            gate-a.md, gate-b.md, environment.md, troubleshooting.md
docker/          Dockerfile for the MATLAB-Runtime-ready derived image (build locally, do not push)
patches/
  validated/       0008-0011  cuPHY fixes needed for Gate A on CUDA 13.1 / r590
scripts/         numbered pipeline, in-container/ helpers, score_logs.py
results/         summary TSV/CSV + trimmed representative logs (no test vectors)
```

## Patches

| # | File | Kind | Why |
|---|---|---|---|
| 0008 | `cuPHY/src/cuphy/crc/crc.cu` | **library bug** | legacy `crc::launch()` never initialised `desc.schUserIdxs[]`, so every TB used TB0's parameters; identity-map it. Production setup path is unaffected. |
| 0009 | `cuPHY/test/fill/test_fill.cpp` | test fix | `CUPHY_BIT` subset starting at bit 16 violates the 32-bit alignment contract and `tensor_fill` has no `CUPHY_BIT` kernel — cannot pass on any GPU; assert the contracts instead. |
| 0010 | `cuPHY/test/tile/test_tile.cpp` | test fix | `Tile.InternalError` launches on a destroyed stream (UB); CUDA 13.1 + r590 segfaults. Skipped unless `CUPHY_TEST_UB_STREAM=1`. |
| 0011 | `cuPHY/src/cuphy/crc/crcTest.cu` | test fix | `UplinkPuschWithTiming` encoded the 0008 bug as the expected result. |

None of the four failures is `sm_120`-specific. Full analysis: [docs/gate-a.md](docs/gate-a.md).

## Known limitations

- **Multi-cell `cubb_gpu_test_bench` does not run on RTX 5090.** It needs `--D/--U` sub-contexts, and `cuCtxCreate` with execution affinity fails with `CUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY` (driver 590.48.01, VM passthrough). So multi-cell slot-budget latency (`measure.py`) is **not measured**. Single-channel examples are unaffected.
- **No `cuphycontroller` + `testMAC` run yet.** Both build, but `PhyDriverCtx` always instantiates `FhProxy` and registers a NIC; that needs a ConnectX-7 / BlueField-3 class fronthaul NIC with DOCA/DPDK.
- **No O-RAN 7.2 RU end-to-end / over-the-air** yet.
- PUSCH HARQ multi-slot vectors are not exercised (they need a slot sequence, not a single TV).
- RTX 5090 is a consumer card in a VM; results are engineering validation, not product qualification.

## Roadmap

- [x] Build Aerial 26.1.2 for `sm_120`
- [x] Gate A — cuPHY unit tests 14/14
- [x] Gate B — L1 channels 208/208 vs. 5GModel vectors
- [ ] Multi-cell latency on 5090 (bench without exec-affinity contexts, or newer driver)
- [ ] Fronthaul NIC (CX7/BF3): `cuphycontroller_scf` + `test_mac` closed loop
- [ ] Publish and validate fronthaul patches (generic DPDK NIC path)
- [ ] O-RAN 7.2 RU integration and OAI L2 end-to-end

## Citation

If this helps your work, please cite it — see [`CITATION.cff`](CITATION.cff).

```bibtex
@misc{openlab_aerial5090_2026,
  author = {Xu, Hao and {OpenLab contributors}},
  title  = {Aerial cuPHY on RTX 5090 (sm\_120): build, patches and L1 validation},
  year   = {2026},
  organization = {OpenLab, Tongji University}
}
```

## Acknowledgements & disclaimer

- Built on [NVIDIA Aerial CUDA-Accelerated RAN](https://github.com/NVIDIA/aerial-cuda-accelerated-ran) (Apache-2.0 source) and its 5GModel / `aerial_mcore` test-vector tooling.
- This repository contains **only OpenLab's own scripts, docs, logs and patch files**. It does **not** contain NVIDIA source trees, binaries, container images, test vectors, MATLAB Runtime, or any NGC credentials. The Aerial container and SDK components obtained from NGC are governed by NVIDIA's own terms; MATLAB Runtime by MathWorks' license.
- NVIDIA, Aerial, CUDA, GeForce and RTX are trademarks of NVIDIA Corporation. MATLAB is a trademark of The MathWorks, Inc. Other names are the property of their owners. This project is **not affiliated with or endorsed by NVIDIA**.

## License

Our scripts, docs and patch files: [Apache-2.0](LICENSE). See [NOTICE](NOTICE).
