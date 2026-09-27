#!/usr/bin/env bash
# Copyright (C) 2026 Ulf Bertilsson
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

make clean
make
make check
python3 tools/render_effect_atlas.py
git diff --exit-code -- assets/c64-horizon-warp-effects.png
