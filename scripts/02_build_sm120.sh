#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Build Aerial 26.1.2 for sm_120 inside the NGC container.
#   TARGETS="" (default) -> full build (921 ninja steps, ~85 min with JOBS=6)
#   TARGETS="cuphy test_fill test_tile crcTest" -> quick incremental rebuild
set -uo pipefail; . "$(dirname "$0")/env.sh"
TARGETS=${TARGETS:-}
ARGS="--build_dir $BUILD_DIR --toolchain native --preset perf --cuda-archs 120"
[ -n "$TARGETS" ] && ARGS="$ARGS --targets $TARGETS" || ARGS="$ARGS --build-only"
st BUILD_START jobs=$JOBS targets="${TARGETS:-all}"
$DOCKER run --rm --gpus all --network host \
  -v "$AERIAL_SRC":$C_SRC -v "$WORK_DIR":$C_WORK -w $C_SRC \
  -e cuBB_SDK=$C_SRC -e CMAKE_BUILD_PARALLEL_LEVEL=$JOBS --entrypoint /bin/bash "$IMAGE" -lc "
  set -o pipefail; nvcc --version | tail -2
  ./testBenches/phase4_test_scripts/build_aerial_sdk.sh $ARGS; rc=\$?
  f=\$(find $BUILD_DIR -name 'libcuphy.so*' -type f | head -1)
  echo '== cubins in' \$f; cuobjdump --list-elf \$f | grep -o 'sm_[0-9a-z]*' | sort | uniq -c
  echo BUILD_RC=\$rc; exit \$rc" > "$LOG_DIR/10_build.log" 2>&1
RC=$?; st "BUILD rc=$RC (log: $LOG_DIR/10_build.log)"; exit $RC
