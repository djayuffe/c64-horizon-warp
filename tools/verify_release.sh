#!/usr/bin/env bash
# Copyright (C) 2026 Ulf Bertilsson
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

make clean
make
make check
python3 tools/render_effect_atlas.py
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum -c SHA256SUMS
else
  shasum -a 256 -c SHA256SUMS
fi
git diff --exit-code -- assets/c64-horizon-warp-effects.png
