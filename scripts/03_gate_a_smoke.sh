#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Gate A: 14 cuPHY unit-test binaries + diagnostics. Expect 14/14 PASS with patches 0008-0011.
set -uo pipefail; . "$(dirname "$0")/env.sh"
mkdir -p "$LOG_DIR/gate-a"; st GATE_A_START
run_in gate_a_smoke.sh -e O=$C_WORK/${LOG_DIR#$WORK_DIR/}/gate-a > "$LOG_DIR/gate-a/30_smoke.log" 2>&1
grep -E "PASS|FAIL|SKIP|sm_|rc=" "$LOG_DIR/gate-a/30_smoke.log" | tee -a "$LOG_DIR/status.log"
st GATE_A_DONE
