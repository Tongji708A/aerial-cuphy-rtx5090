# Patches

Base: `NVIDIA/aerial-cuda-accelerated-ran` tag `26.1.2` (commit `efe0d8c7`), Apache-2.0.
Our changes are Apache-2.0 as well (Apache-2.0 §4(b): modified files are marked — validated patches add an `OpenLab NNNN` comment at each change).

| Dir | Patches | Format | Status |
|---|---|---|---|
| `validated/` | 0008–0011 | `diff -u`, `patch -p1` | **Validated** — Gate A 14/14, Gate B 208/208 |

## validated/
- `0008` cuPHY `crc.cu`: legacy `crc::launch()` initialises `desc.schUserIdxs[]` (library bug).
- `0009` `test_fill.cpp`: assert the CUPHY_BIT subset/fill contracts instead of an impossible fill.
- `0010` `test_tile.cpp`: skip the destroyed-stream UB test unless `CUPHY_TEST_UB_STREAM=1`.
- `0011` `crcTest.cu`: `UplinkPuschWithTiming` expects pass once 0008 is applied.


Fronthaul (FH) patches are under development and will be published once validated with a real FH NIC and O-RU.
