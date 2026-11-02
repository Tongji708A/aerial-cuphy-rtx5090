# Contributing

Thanks for helping. Short rules:

1. **Never commit NVIDIA or third-party payloads**: no Aerial source trees, binaries, container images, test vectors (`*.h5`), MATLAB Runtime, or credentials (NGC keys, tokens). Patches as diffs only.
2. Reports from other GPUs / drivers are welcome — open an issue with `nvidia-smi`, the image tag, `scripts/score_logs.py` output and the failing log (trimmed).
3. New patches: one fix per file, `diff -u` against tag `26.1.2`, an `OpenLab NNNN` comment at the change, and an entry in `patches/README.md` saying whether it is validated.
4. Scripts: bash with `set -u`, no hard-coded hosts, IPs, users or paths — use `scripts/env.sh` variables.
5. By contributing you agree your contribution is licensed under Apache-2.0.

Note: upstream NVIDIA Aerial does not accept external contributions; fixes that belong upstream should be reported to NVIDIA through their channels.
