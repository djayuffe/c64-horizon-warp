#!/usr/bin/env python3
"""Validate the canonical C64 BASIC SYS 4096 PRG header."""

from pathlib import Path
import sys

path = Path(sys.argv[1])
data = path.read_bytes()
expected = bytes((0x01, 0x08, 0x0B, 0x08, 0x0A, 0x00, 0x9E)) + b"4096\x00\x00\x00"
if not data.startswith(expected):
    raise SystemExit(f"{path}: expected CBM BASIC '10 SYS4096' header")
if len(data) <= len(expected):
    raise SystemExit(f"{path}: missing machine-code payload")
print(f"{path}: valid CBM BASIC SYS4096 PRG ({len(data)} bytes)")
