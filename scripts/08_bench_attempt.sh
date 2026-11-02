#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Multi-cell cubb_gpu_test_bench attempt. On RTX 5090 (driver 590.48.01, VM passthrough) this
# fails in cuCtxCreate with CUDA_ERROR_UNSUPPORTED_EXEC_AFFINITY -- kept to reproduce the limitation.
set -uo pipefail; . "$(dirname "$0")/env.sh"
O=$LOG_DIR/bench; mkdir -p "$O"; st BENCH_START
run_in bench.sh --privileged -e O=$C_WORK/${O#$WORK_DIR/} | tee "$O/bench_outer.log"
grep -l UNSUPPORTED_EXEC_AFFINITY "$O"/*.log && echo "=> affinity limitation reproduced"
st BENCH_DONE
