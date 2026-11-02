#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Runs inside the Aerial container. Env: B (build dir), O (log dir).
mkdir -p "$O"
echo "=== arch"; f=$(find $B -name "libcuphy.so*" -type f | head -1); echo "## $f"; cuobjdump --list-elf $f | grep -o "sm_[0-9a-z]*" | sort | uniq -c
echo "=== smoke"
for t in test_elementwise test_fill test_tile test_rng test_reduction test_convert crcTest test_polar_encoder test_polar_decoder testModulationMapper tensor_desc_tests cuphy_api_tests cuphy_hpp_tests test_ldpc_internal_rc; do
  b=$(find $B -type f -name $t -executable | head -1); [ -z "$b" ] && { echo -e "$t\tSKIP\tno_binary"; continue; }
  ( cd $(dirname $b); timeout 900 $b > $O/run_$t.log 2>&1 ); rc=$?
  p=$(grep -Eo "\[  PASSED  \] [0-9]+ test" $O/run_$t.log | grep -Eo "[0-9]+" | head -1)
  f=$(grep -Eo "\[  FAILED  \] [0-9]+ test" $O/run_$t.log | grep -Eo "[0-9]+" | head -1)
  s=$(grep -Eo "\[  SKIPPED \] [0-9]+ test" $O/run_$t.log | grep -Eo "[0-9]+" | head -1)
  [ $rc -eq 0 ] && r=PASS || r=FAIL; echo -e "$t\t$r\trc=$rc passed=${p:-?} failed=${f:-0} skipped=${s:-0}"
done
echo "=== diag: destroyed-stream UB test opt-in (segfaults on CUDA 13.1 / r590 -> confirms 0010 rationale)"
b=$(find $B -type f -name test_tile -executable | head -1)
( cd $(dirname $b); CUPHY_TEST_UB_STREAM=1 timeout 120 $b --gtest_filter=Tile.InternalError > $O/diag_tile_ub.log 2>&1 ); echo "tile_ub rc=$?"
( cd $(dirname $b); timeout 600 compute-sanitizer --tool memcheck $b > $O/diag_tile_memcheck.log 2>&1 ); echo "tile_memcheck rc=$?"
b=$(find $B -type f -name crcTest -executable | head -1)
( cd $(dirname $b); timeout 900 compute-sanitizer --tool memcheck $b --gtest_filter=CRC_GPU_UPLINK_PUSCH.* > $O/diag_crc_memcheck.log 2>&1 ); echo "crc_memcheck rc=$?"
