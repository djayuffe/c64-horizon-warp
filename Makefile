# Copyright (C) 2026 Ulf Bertilsson
# SPDX-License-Identifier: GPL-3.0-or-later
ACME ?= acme
VICE ?= x64sc
SOURCE := src/c64-horizon-warp.s
TARGET := build/c64-horizon-warp.prg

.PHONY: all check run clean

all: $(TARGET)

$(TARGET): $(SOURCE) | build

	$(ACME) --strict-segments -f cbm -o $@ $<

build:
	mkdir -p $@

check: $(TARGET)
	test -s $(TARGET)
	python3 tools/check_prg.py $(TARGET)

run: $(TARGET)
	$(VICE) -autostartprgmode 1 -autostart $(TARGET)

clean:
	rm -rf build
