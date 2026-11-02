#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Fetch the public Aerial CUDA-Accelerated RAN source at tag 26.1.2.
# Git LFS objects under 5GModel/ are needed for test-vector generation.
set -euo pipefail; . "$(dirname "$0")/env.sh"
if [ ! -d "$AERIAL_SRC/.git" ]; then
  GIT_LFS_SKIP_SMUDGE=1 git clone https://github.com/NVIDIA/aerial-cuda-accelerated-ran.git "$AERIAL_SRC"
fi
git -C "$AERIAL_SRC" checkout -q "$AERIAL_COMMIT"
# Pull LFS content except cuMAC (not needed for cuPHY L1 validation).
git -C "$AERIAL_SRC" lfs pull --exclude="cuMAC/**" || echo "WARN: git lfs pull failed; TV generation needs 5GModel LFS files"
git -C "$AERIAL_SRC" log --oneline -1
