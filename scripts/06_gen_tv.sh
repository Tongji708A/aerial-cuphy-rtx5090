#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Generate cuPHY test vectors with aerial_mcore + MATLAB Runtime (REGRESSION_MODE=2 = compact set).
# Output ~21 GB / ~4100 files. PUSCH generation can be OOM-killed with 15 GB RAM; it still leaves
# hundreds of usable vectors. Set CHS to limit channels.
set -uo pipefail; . "$(dirname "$0")/env.sh"
CHS=${CHS:-"ssb pdcch pdsch pusch prach pucch csirs"}; TLIM=${TLIM:-3600}
mkdir -p "$WORK_DIR/tvgen"
for ch in $CHS; do
 s=$(date +%s)
 $DOCKER run --rm --network host -v "$AERIAL_SRC":$C_SRC -v "$WORK_DIR":$C_WORK -v "$MATLAB_DIR":/usr/local/MATLAB \
   -w $C_WORK/tvgen -e cuBB_SDK=$C_SRC --entrypoint /bin/bash "$IMAGE_MCR" -lc "
  pip install -q $C_SRC/5GModel/aerial_mcore/aerial_pkg/dist/aerial_mcore-*.whl 2>&1 | tail -2
  source $C_SRC/5GModel/aerial_mcore/scripts/setup.sh
  export REGRESSION_MODE=2
  timeout $TLIM python3 $C_SRC/5GModel/aerial_mcore/examples/example_5GModel_regression.py $ch; echo TVRC=\$?
  chmod -R a+rwX $C_WORK/tvgen" > "$LOG_DIR/30_tv_$ch.log" 2>&1
 st "TV $ch $(grep -o 'TVRC=[0-9]*' "$LOG_DIR/30_tv_$ch.log" | tail -1) $(( $(date +%s)-s ))s nTV=$(ls "$TV_DIR" 2>/dev/null | wc -l)"
done
