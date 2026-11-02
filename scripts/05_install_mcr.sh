#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Install MATLAB Runtime R2023a Update 1 (silent) into $MATLAB_DIR, mounted as /usr/local/MATLAB.
# Download the zip yourself from MathWorks and accept its license; it is NOT redistributed here.
set -uo pipefail; . "$(dirname "$0")/env.sh"
[ -f "$MCR_ZIP" ] || { echo "missing $MCR_ZIP (download MATLAB_Runtime_R2023a_Update_1_glnxa64.zip from mathworks.com)"; exit 1; }
mkdir -p "$MATLAB_DIR" "$(dirname "$MCR_ZIP")/x"
cp "$(dirname "$0")/unz.py" "$(dirname "$MCR_ZIP")/"
st MCR_START
$DOCKER run --rm -v "$(dirname "$MCR_ZIP")":/mcr -v "$MATLAB_DIR":/usr/local/MATLAB --entrypoint /bin/bash "$IMAGE_MCR" -lc "
 set -e; cd /mcr/x; rm -rf /mcr/x/*
 # unz.py: plain 'unzip' drops the symlinks inside the MCR zip and the installer then fails.
 python3 /mcr/unz.py /mcr/$(basename "$MCR_ZIP") /mcr/x
 chmod +x install bin/glnxa64/* sys/java/jre/glnxa64/jre/bin/* 2>/dev/null || true
 ./install -agreeToLicense yes -destinationFolder /usr/local/MATLAB/MATLAB_Runtime -mode silent
 ls /usr/local/MATLAB/MATLAB_Runtime" > "$LOG_DIR/20_mcr.log" 2>&1
st "MCR_INSTALL rc=$?"
