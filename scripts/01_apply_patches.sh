#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
# Apply OpenLab patches.
#   validated/     0008-0011 : needed for Gate A 14/14 (plain 'diff -u', apply with patch -p1)
set -euo pipefail; . "$(dirname "$0")/env.sh"
P=$(cd "$(dirname "$0")/../patches" && pwd)
cd "$AERIAL_SRC"
for p in "$P"/validated/*.patch; do
  if patch -p1 -R --dry-run -s -f < "$p" >/dev/null 2>&1; then echo "already applied: $(basename "$p")"
  else patch -p1 -s < "$p" && echo "applied: $(basename "$p")"; fi
done
