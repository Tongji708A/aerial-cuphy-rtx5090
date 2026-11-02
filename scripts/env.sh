#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Shared settings. Source this file; override any variable from the environment.
: "${WORK_DIR:=$HOME/aerial_work}"                       # everything lives here
: "${AERIAL_SRC:=$WORK_DIR/src-26.1.2}"                  # NVIDIA/aerial-cuda-accelerated-ran @ 26.1.2
: "${AERIAL_TAG:=26.1.2}"
: "${AERIAL_COMMIT:=efe0d8c73e3ecc83a36ccdfec631d8f34a2e980f}"
: "${IMAGE:=nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb}"   # pull with your own NGC key
: "${IMAGE_MCR:=local/aerial-26-1-cubb-mcr:latest}"       # built by docker/Dockerfile
: "${BUILD_DIR:=build.sm120}"
: "${MATLAB_DIR:=$WORK_DIR/MATLAB}"                      # MATLAB Runtime R2023a install target
: "${MCR_ZIP:=$WORK_DIR/mcr/MATLAB_Runtime_R2023a_Update_1_glnxa64.zip}"
: "${TV_DIR:=$WORK_DIR/tvgen/GPU_test_input}"            # generated test vectors (~21 GB)
: "${LOG_DIR:=$WORK_DIR/logs}"
: "${JOBS:=6}"                                            # 6 was safe with 15 GB RAM; raise if you have more
: "${DOCKER:=sudo docker}"
mkdir -p "$LOG_DIR"
st(){ echo "$(date -Is) $*" | tee -a "$LOG_DIR/status.log"; }
# Container paths (keep in sync with all scripts)
C_SRC=/opt/aerial/src; C_WORK=/work
# Run an in-container script from scripts/in-container/ with the standard mounts.
run_in(){ local s=$1; shift
  $DOCKER run --rm --gpus all --network host "$@" \
    -v "$AERIAL_SRC":$C_SRC -v "$WORK_DIR":$C_WORK -v "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/in-container":/oscripts:ro \
    -e B=$C_SRC/$BUILD_DIR -e TV=$C_WORK/${TV_DIR#$WORK_DIR/} -e CAP="${CAP:-16}" \
    -w $C_WORK --entrypoint /bin/bash "$IMAGE" /oscripts/"$s"; }
