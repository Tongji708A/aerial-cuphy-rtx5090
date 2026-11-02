#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Gate B: run cuPHY per-channel examples on the first CAP vectors of each channel,
# in both modes (m0 streams / m1 graphs; PDSCH uses g0/g1), then score with score_logs.py.
set -uo pipefail; . "$(dirname "$0")/env.sh"
O=$LOG_DIR/gate-b/run; mkdir -p "$O"; st "GATE_B_START cap=${CAP:-16}"
run_in run_channels.sh -e O=$C_WORK/${O#$WORK_DIR/} | tee "$LOG_DIR/gate-b/40_run.log" | grep _DONE
python3 "$(dirname "$0")/score_logs.py" "$O" --tsv "$LOG_DIR/gate-b/summary.tsv" --latency "$LOG_DIR/gate-b/latency.csv" | tee -a "$LOG_DIR/status.log"
