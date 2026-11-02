#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Runs inside the Aerial container. Env: B (build dir), TV (test-vector dir), O (log dir), CAP.
E=$B/cuPHY/examples; mkdir -p "$O"
pick(){ ls $TV/$1 2>/dev/null | grep -vE "disabled${2:+|$2}" | head -$CAP; }
for tv in $(pick '*SSB_gNB_CUPHY*.h5'); do bn=$(basename $tv .h5)
  for m in 0 1; do $E/ss/testSS -i $tv -m $m > $O/ssb_${bn}_m$m.log 2>&1; done; done; echo SSB_DONE
for tv in $(pick '*PDSCH_gNB_CUPHY*.h5'); do bn=$(basename $tv .h5)
  for g in 0 1; do $E/pdsch_tx/cuphy_ex_pdsch_tx $tv 2 0 $g > $O/pdsch_${bn}_g$g.log 2>&1; done; done; echo PDSCH_DONE
# HARQ vectors need a multi-slot sequence; skip them for single-TV runs.
for tv in $(pick '*PUSCH_gNB_CUPHY*.h5' HARQ); do bn=$(basename $tv .h5)
  for m in 0 1; do $E/pusch_rx_multi_pipe/cuphy_ex_pusch_rx_multi_pipe -i $tv -m $m -r 2 > $O/pusch_${bn}_m$m.log 2>&1; done; done; echo PUSCH_DONE
for tv in $(pick '*PDCCH_gNB_CUPHY*.h5'); do bn=$(basename $tv .h5)
  printf 'cells: 1\nslots:\n    - PDCCH:\n        - %s\n' "$tv" > /tmp/p.yaml
  for m in 0 1; do $E/pdcch_tx_multi_cell/cuphy_ex_pdcch_tx_multi_cell -i /tmp/p.yaml -k -m $m -r 5 > $O/pdcch_${bn}_m$m.log 2>&1; done; done; echo PDCCH_DONE
for tv in $(pick '*PUCCH_F*_gNB_CUPHY*.h5'); do bn=$(basename $tv .h5)
  for m in 0 1; do $E/pucch_rx_pipeline/cuphy_ex_pucch_rx_pipeline -i $tv -m $m -r 2 > $O/pucch_${bn}_m$m.log 2>&1; done; done; echo PUCCH_DONE
for tv in $(pick '*PRACH_gNB_CUPHY*.h5'); do bn=$(basename $tv .h5)
  for m in 0 1; do $E/prach_receiver_multi_cell/prach_receiver_multi_cell -i $tv -n 1 -m $m -k -r 2 > $O/prach_${bn}_m$m.log 2>&1; done; done; echo PRACH_DONE
BIN=$(ls $E/csirs_tx_multi_cell/cuphy_ex_*csirs* 2>/dev/null | head -1)
for tv in $(pick '*CSIRS_gNB_CUPHY*.h5'); do bn=$(basename $tv .h5)
  printf 'cells: 1\nslots:\n    - CSIRS:\n        - %s\n' "$tv" > /tmp/c.yaml
  $BIN -i /tmp/c.yaml -k -r 5 > $O/csirs_${bn}.log 2>&1 || $BIN $tv 2 0 0 > $O/csirs_${bn}.log 2>&1; done; echo CSIRS_DONE
