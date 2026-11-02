#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Build the derived image that adds the shared libraries MATLAB Runtime needs (libnss3 etc.).
set -euo pipefail; . "$(dirname "$0")/env.sh"
$DOCKER build --build-arg BASE_IMAGE="$IMAGE" -t "$IMAGE_MCR" "$(dirname "$0")/../docker"
