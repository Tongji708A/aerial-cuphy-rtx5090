# SPDX-License-Identifier: Apache-2.0
# Copyright 2026 OpenLab contributors (Tongji University)
#
# Derived image: NVIDIA Aerial 26-1-cubb + the shared libraries MATLAB Runtime R2023a needs
# for aerial_mcore test-vector generation (missing libnss3 makes the MCR installer / engine fail).
#
# The base image is NOT redistributed. Pull it yourself from NGC with your own API key:
#   docker login nvcr.io        # user: $oauthtoken, password: <your NGC API key>
#   docker pull nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb
# Build:
#   docker build --build-arg BASE_IMAGE=nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb \
#                -t local/aerial-26-1-cubb-mcr:latest docker/
# Do not push the result to a public registry: it contains NVIDIA software under NGC terms.
ARG BASE_IMAGE=nvcr.io/nvidia/aerial/aerial-cuda-accelerated-ran:26-1-cubb
FROM ${BASE_IMAGE}
USER root
# Optional: --build-arg APT_MIRROR=http://<your-mirror>/ubuntu if archive.ubuntu.com is slow/blocked.
ARG APT_MIRROR=
ENV DEBIAN_FRONTEND=noninteractive
RUN if [ -n "$APT_MIRROR" ]; then \
      sed -i "s#http://[a-z.]*ubuntu.com/ubuntu/\?#${APT_MIRROR}#g" /etc/apt/sources.list /etc/apt/sources.list.d/*.sources 2>/dev/null || true; \
    fi && \
    apt-get update && apt-get install -y --no-install-recommends \
      libnss3 libnspr4 libxcomposite1 libxtst6 libxt6 libxi6 libxrender1 libxrandr2 libxdamage1 \
      libxfixes3 libxcursor1 libxinerama1 libasound2 libatk1.0-0 libatk-bridge2.0-0 libgtk-3-0 \
      libcups2 libgbm1 libxss1 libx11-xcb1 libdrm2 libsm6 libice6 libxkbcommon0 libpango-1.0-0 libcairo2 \
    && rm -rf /var/lib/apt/lists/*
