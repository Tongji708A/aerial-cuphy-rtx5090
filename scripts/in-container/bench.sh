#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Runs inside the Aerial container. Env: B, TV, O.
BIN=$B/testBenches/cubb_gpu_test_bench/cubb_gpu_test_bench; mkdir -p "$O"; cd "$O"
python3 - <<PY
import glob
T="$TV"
pd=sorted(f for f in glob.glob(T+"/*PDSCH_gNB_CUPHY*.h5") if "disabled" not in f)[:4]
pu=sorted(f for f in glob.glob(T+"/*PUSCH_gNB_CUPHY*.h5") if "disabled" not in f and "HARQ" not in f)[:4]
for n in (1,4):
    L=["cells: %d"%n,"slots:","    - PDSCH:"]+["        - "+pd[i%len(pd)] for i in range(n)]
    L+=["    - PUSCH:"]+["        - "+pu[i%len(pu)] for i in range(n)]
    open("bench_%dc.yaml"%n,"w").write("\n".join(L)+"\n")
PY
# --D/--U are mandatory (otherwise 'nCtxts = 0'); -n (green contexts) and --M (SM affinity) omitted.
for n in 1 4; do for m in 0 1; do
  echo "==== ${n} cell(s) m=$m --D --U"
  timeout 300 $BIN -i bench_${n}c.yaml -m $m -r 30 -w 10000 -g 0 --D --U > bench_${n}c_m$m.log 2>&1; echo RC=$?
  grep -E "UNSUPPORTED|ERROR|terminate|nCtxts" bench_${n}c_m$m.log | tail -5
done; done
timeout 300 $BIN -i bench_1c.yaml -m 0 -r 30 -w 10000 -g 0 -u 3 --D --U > bench_1c_u3_m0.log 2>&1; echo RC_U3=$?
grep -E "UNSUPPORTED|ERROR|terminate" bench_1c_u3_m0.log | tail -5
