#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors
"""Re-score cuPHY example logs produced by 05_run_channels.sh.

Usage: score_logs.py <run_log_dir> [--tsv out.tsv] [--latency out.csv]

Pass criteria (per channel) -- see docs/gate-b.md for why these differ
from the naive 'Test PASS' grep used in the first pass:
  ssb, pdcch, prach, csirs : 'Test PASS' present
  pdsch                    : 'Found 0 mismatched' present, no mismatched>0
  pusch                    : every 'MismatchedCRC CBs N' and 'MismatchedCRC TBs N' is 0,
                             BLER 0, and no 'FATAL'
  pucch                    : every 'found N mismatches' has N == 0, no 'FATAL'
HARQ multi-slot PUSCH vectors are skipped (need a slot sequence, not a single TV).
"""
import argparse, csv, glob, os, re, statistics as st, sys

LAT = {  # channel -> (regex, unit label)
    "pdsch": r"DL pipeline: ([\d.]+) us",
    "pdcch": r"GPU-run only: ([\d.]+) us",
    "pusch": r"Total time usec GPU \(CUDA event\) ([\d.]+)",
}

def score(ch, s):
    if ch in ("ssb", "pdcch", "prach", "csirs"):
        return "Test PASS" in s
    if ch == "pdsch":
        n = [int(x) for x in re.findall(r"Found (\d+) mismatched", s)]
        return bool(n) and max(n) == 0
    if ch == "pusch":
        if "FATAL" in s: return False
        crc = [int(x) for x in re.findall(r"MismatchedCRC (?:CBs|TBs) (\d+)", s)]
        bler = [float(x) for x in re.findall(r"Block Error Rate\s*: ([\d.]+)", s)]
        return bool(crc) and max(crc) == 0 and bool(bler) and max(bler) == 0.0
    if ch == "pucch":
        if "FATAL" in s: return False
        n = [int(x) for x in re.findall(r"found (\d+) mismatches", s)]
        return bool(n) and max(n) == 0
    raise ValueError(ch)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dir"); ap.add_argument("--tsv"); ap.add_argument("--latency")
    a = ap.parse_args()
    rows, lat = [], []
    for f in sorted(glob.glob(os.path.join(a.dir, "*.log"))):
        b = os.path.basename(f)[:-4]
        ch = b.split("_", 1)[0]
        if ch not in ("ssb", "pdsch", "pdcch", "pusch", "pucch", "prach", "csirs"): continue
        if "HARQ" in b: continue
        m = re.search(r"_([mg]\d)$", b)
        mode = m.group(1) if m else "m0"
        tv = b[len(ch) + 1:len(b) - (len(mode) + 1 if m else 0)]
        s = open(f, errors="ignore").read()
        ok = score(ch, s)
        rows.append((ch, mode, tv, "PASS" if ok else "FAIL"))
        if ch in LAT:
            v = [float(x) for x in re.findall(LAT[ch], s)]
            if v: lat.append((ch, mode, tv, v[-1]))
    tot = {}
    for ch, _, _, r in rows:
        p, t = tot.get(ch, (0, 0)); tot[ch] = (p + (r == "PASS"), t + 1)
    for ch in ("ssb", "pdsch", "pdcch", "pusch", "pucch", "prach", "csirs"):
        if ch in tot: print(f"{ch:6s} {tot[ch][0]}/{tot[ch][1]}")
    P = sum(p for p, _ in tot.values()); T = sum(t for _, t in tot.values())
    print(f"TOTAL  {P}/{T}")
    for ch in LAT:
        v = [x for c, _, _, x in lat if c == ch]
        if v: print(f"{ch} latency us: n={len(v)} min={min(v):.1f} median={st.median(v):.1f} max={max(v):.1f}")
    if a.tsv:
        with open(a.tsv, "w", newline="") as fh:
            w = csv.writer(fh, delimiter="\t"); w.writerow(["channel", "mode", "tv", "result"]); w.writerows(rows)
    if a.latency:
        with open(a.latency, "w", newline="") as fh:
            w = csv.writer(fh); w.writerow(["channel", "mode", "tv", "latency_us"]); w.writerows(lat)
    return 0 if P == T else 1

if __name__ == "__main__":
    sys.exit(main())
