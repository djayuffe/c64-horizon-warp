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
	@file $(TARGET) | grep -q 'CBM BASIC, SYS 4096'

run: $(TARGET)
	$(VICE) -autostartprgmode 1 -autostart $(TARGET)

clean:
	rm -rf build
