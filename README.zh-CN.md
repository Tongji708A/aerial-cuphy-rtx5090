<div align="center">

# Aerial cuPHY on RTX 5090 (sm_120)

**在消费级 GeForce RTX 5090 上编译（Blackwell `sm_120`）并验证 NVIDIA Aerial CUDA-Accelerated RAN 26.1 cuPHY L1。**

[![CUDA](https://img.shields.io/badge/CUDA-13.1-76B900?logo=nvidia&logoColor=white)](#软硬件矩阵)
[![Driver](https://img.shields.io/badge/driver-590.48.01-76B900)](#软硬件矩阵)
[![GPU](https://img.shields.io/badge/GPU-RTX%205090%20(sm__120)-black?logo=nvidia)](#软硬件矩阵)
[![Status](https://img.shields.io/badge/status-L1%20validated-brightgreen)](#结论)
[![Fronthaul](https://img.shields.io/badge/fronthaul%20%2F%20RU-in%20progress-orange)](#已知限制)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](LICENSE)

[English](README.md) | 简体中文

</div>

> **非官方社区项目**，与 NVIDIA 无隶属关系，也未获 NVIDIA 认可或背书。RTX 5090 / x86 不是 Aerial 官方认证平台。

## 结论

OpenLab 已在消费级 RTX 5090 上完成 Aerial cuPHY L1 适配与验证；整栈前传与 RU 联调进行中。

| 关口 | 内容 | 结果 |
|---|---|---|
| 编译 | Aerial 26.1.2，`--cuda-archs 120`，完整 SDK（921/921） | ✅ `libcuphy.so` 含 65 个 `sm_120` cubin |
| Gate A | 14 个 cuPHY 单元测试 | ✅ **14/14 通过**（需 [补丁 0008–0011](patches/validated/)） |
| Gate B | 各信道 cuPHY 示例对照 MATLAB 生成的测试向量，streams + graphs | ✅ **208/208 通过** |

| 信道 | 通过 | 单 cell 时延（本次实测） |
|---|---|---|
| SSB | 32/32 | — |
| PDSCH | 32/32 | DL pipeline：streams 中位 **~60 µs**（49–72），graphs **~36 µs**（26–44） |
| PDCCH | 32/32 | GPU-run：m0 **~14.6 µs**，m1 **~13.1 µs** |
| PUSCH | 32/32 | GPU 总时长：m0 **~148 µs**，m1 **~155 µs**；BLER 0，CRC 0 错 |
| PUCCH F0–F3 | 32/32 | UCI 0 错 |
| PRACH | 32/32 | — |
| CSI-RS | 16/16 | — |

时延是 cuPHY 示例程序单 cell 计时，不是多 cell 时隙预算测量。

## 软硬件矩阵

| 层 | 实测 |
|---|---|
| 宿主机 | Lenovo WR5220 G5（2U 双路 x86_64），Proxmox VE |
| 虚拟机 | KVM，GPU 整卡 PCIe 直通；8 vCPU / 16 GB 内存 |
| 系统 | Ubuntu 24.04.4 LTS，内核 6.8.0 |
| GPU / 驱动 | RTX 5090 32 GB（CC 12.0）/ 590.48.01 |
| 容器 | `nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb`，CUDA 13.1 |
| 源码 | `NVIDIA/aerial-cuda-accelerated-ran` tag `26.1.2` |
| 测试向量 | `aerial_mcore` + MATLAB Runtime R2023a U1，`REGRESSION_MODE=2` |

## 快速开始

需要自备 NGC API Key 和 MATLAB Runtime R2023a U1 安装包（本仓库不提供）。步骤与英文版相同：

```bash
docker login nvcr.io && docker pull nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb
scripts/00_fetch_source.sh && scripts/01_apply_patches.sh
scripts/02_build_sm120.sh && scripts/03_gate_a_smoke.sh          # 期望 14/14
scripts/04_build_mcr_image.sh && scripts/05_install_mcr.sh && scripts/06_gen_tv.sh
CAP=16 scripts/07_run_channels.sh                                 # 期望 208/208
```

无 GPU 也可复核我们发布的日志：`python3 scripts/score_logs.py results/logs/gate-b/run`。

## 已知限制

- `cubb_gpu_test_bench` 多 cell 压测在 5090 上报 `CUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY`，多 cell 时延未测。
- `cuphycontroller` + `testMAC` 已编出，但必须有 ConnectX-7 / BlueField-3 前传网卡才能启动。
- 尚未接 O-RAN 7.2 RU 做端到端空口。

## 路线图

- [x] sm_120 编译 · [x] Gate A 14/14 · [x] Gate B 208/208
- [ ] 5090 多 cell 时延 · [ ] 前传网卡 + cuphycontroller/testMAC · [ ] 发布并验证前传补丁 · [ ] 7.2 RU 与 OAI L2 端到端

## 引用与致谢

引用见 [`CITATION.cff`](CITATION.cff)（Hao Xu，同济大学 / OpenLab）。基于 [NVIDIA Aerial CUDA-Accelerated RAN](https://github.com/NVIDIA/aerial-cuda-accelerated-ran)（Apache-2.0）。
本仓库只含 OpenLab 自己的脚本、文档、日志与补丁文件，不含 NVIDIA 源码、二进制、镜像、测试向量、MATLAB Runtime 或任何密钥。NVIDIA、Aerial、CUDA、GeForce、RTX 是 NVIDIA 的商标。

## 许可证

[Apache-2.0](LICENSE)，见 [NOTICE](NOTICE)。
