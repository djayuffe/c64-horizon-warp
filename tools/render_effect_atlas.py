#!/usr/bin/env python3
"""Render a source-derived overview of C64 Horizon Warp's visual sections."""

from pathlib import Path
import math
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "c64-horizon-warp-effects.png"

PALETTE = ((0, 0, 0), (255, 255, 255), (104, 55, 43), (112, 164, 178),
           (111, 61, 134), (88, 141, 67), (53, 40, 121), (184, 199, 111),
           (111, 79, 37), (67, 57, 0), (154, 103, 89), (68, 68, 68),
           (108, 108, 108), (154, 210, 132), (108, 94, 181), (149, 149, 149))
RAINBOW = (6, 14, 3, 13, 1, 13, 3, 14, 6, 14, 3, 13, 1, 13, 3, 14)
ICE = (6, 14, 3, 1, 1, 3, 14, 6, 0, 6, 14, 3, 1, 1, 3, 14)
FIRE = (0, 9, 2, 8, 2, 10, 7, 10, 15, 7, 10, 7, 8, 2, 9, 0)
FONT = {
    "A": ("01110", "10001", "10001", "11111", "10001", "10001", "10001"),
    "B": ("11110", "10001", "10001", "11110", "10001", "10001", "11110"),
    "C": ("01111", "10000", "10000", "10000", "10000", "10000", "01111"),
    "D": ("11110", "10001", "10001", "10001", "10001", "10001", "11110"),
    "E": ("11111", "10000", "10000", "11110", "10000", "10000", "11111"),
    "F": ("11111", "10000", "10000", "11110", "10000", "10000", "10000"),
    "G": ("01111", "10000", "10000", "10111", "10001", "10001", "01110"),
    "H": ("10001", "10001", "10001", "11111", "10001", "10001", "10001"),
    "I": ("11111", "00100", "00100", "00100", "00100", "00100", "11111"),
    "J": ("00111", "00010", "00010", "00010", "10010", "10010", "01100"),
    "K": ("10001", "10010", "10100", "11000", "10100", "10010", "10001"),
    "L": ("10000", "10000", "10000", "10000", "10000", "10000", "11111"),
    "M": ("10001", "11011", "10101", "10101", "10001", "10001", "10001"),
    "N": ("10001", "11001", "10101", "10011", "10001", "10001", "10001"),
    "O": ("01110", "10001", "10001", "10001", "10001", "10001", "01110"),
    "P": ("11110", "10001", "10001", "11110", "10000", "10000", "10000"),
    "Q": ("01110", "10001", "10001", "10001", "10101", "10010", "01101"),
    "R": ("11110", "10001", "10001", "11110", "10100", "10010", "10001"),
    "S": ("01111", "10000", "10000", "01110", "00001", "00001", "11110"),
    "T": ("11111", "00100", "00100", "00100", "00100", "00100", "00100"),
    "U": ("10001", "10001", "10001", "10001", "10001", "10001", "01110"),
    "V": ("10001", "10001", "10001", "10001", "10001", "01010", "00100"),
    "W": ("10001", "10001", "10001", "10101", "10101", "10101", "01010"),
    "X": ("10001", "01010", "00100", "00100", "00100", "01010", "10001"),
    "Y": ("10001", "01010", "00100", "00100", "00100", "00100", "00100"),
    "Z": ("11111", "00010", "00100", "01000", "10000", "10000", "11111"),
    "*": ("00000", "10101", "01110", "11111", "01110", "10101", "00000"),
    "-": ("00000", "00000", "00000", "11111", "00000", "00000", "00000"),
    " ": ("00000",) * 7,
}


def chunk(kind: bytes, data: bytes) -> bytes:
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data) & 0xffffffff)


def fill(image, x, y, width, height, color):
    for row in range(max(0, y), min(len(image), y + height)):
        image[row][max(0, x):min(len(image[0]), x + width)] = [color] * max(0, min(len(image[0]), x + width) - max(0, x))


def text(image, x, y, value, color, scale=2):
    for character in value:
        glyph = FONT.get(character, FONT[" "])
        for row, bits in enumerate(glyph):
            for col, bit in enumerate(bits):
                if bit == "1":
                    fill(image, x + col * scale, y + row * scale, scale, scale, color)
        x += 6 * scale


def panel(image, x, y, title, phase):
    w, h = 440, 250
    fill(image, x, y, w, h, PALETTE[6])
    fill(image, x, y, w, 4, PALETTE[14])
    fill(image, x, y + h - 4, w, 4, PALETTE[3])
    text(image, x + 12, y + 12, title, PALETTE[1], 2)
    return x + 8, y + 38, w - 16, h - 46, phase


def main():
    width, height = 920, 580
    image = [[PALETTE[0] for _ in range(width)] for _ in range(height)]
    text(image, 24, 16, "C64 HORIZON WARP - EFFECT ATLAS", PALETTE[14], 3)
    text(image, 24, 44, "SOURCE-DERIVED PAL VISUAL SECTIONS", PALETTE[3], 2)

    x, y, w, h, phase = panel(image, 16, 76, "LOGO SHINE + SCROLLER", 3)
    for row in range(5, 16):
        color = PALETTE[RAINBOW[(phase + row * 3) & 15]]
        fill(image, x, y + row * 6, w, 6, color)
    text(image, x + 78, y + 24, "** HORIZON WARP **", PALETTE[1], 3)
    text(image, x + 88, y + 52, "MAXIMUM EYE CANDY", PALETTE[14], 2)
    fill(image, x, y + h - 28, w, 3, PALETTE[3])
    text(image, x + 12, y + h - 20, "ULTIMATE HORIZONWARP DEMO", PALETTE[7], 2)

    x, y, w, h, phase = panel(image, 464, 76, "SPRITE MOTION + COLOR WAVE", 9)
    for row in range(14):
        fill(image, x, y + row * 13, w, 13, PALETTE[RAINBOW[(phase + row * 3) & 15]])
    for sprite in range(8):
        sx = x + 26 + ((sprite * 49 + 40) % (w - 50))
        sy = y + 32 + int((math.sin((sprite + phase) * 0.8) + 1) * 52)
        col = PALETTE[FIRE[(sprite * 2 + phase) & 15]]
        fill(image, sx, sy, 28, 13, col)
        fill(image, sx + 7, sy - 5, 14, 23, col)

    x, y, w, h, phase = panel(image, 16, 326, "PLASMA BACKGROUND", 5)
    for py in range(0, h, 5):
        for px in range(0, w, 5):
            wave = int(math.sin((px + phase * 9) / 24) * 5 + math.cos((py - phase * 7) / 20) * 5) & 15
            fill(image, x + px, y + py, 5, 5, PALETTE[RAINBOW[wave]])
    text(image, x + 104, y + 84, "PLASMA WAVES", PALETTE[1], 3)

    x, y, w, h, phase = panel(image, 464, 326, "LOWER RASTER BARS", 12)
    for bar in range(20):
        fill(image, x, y + bar * 9, w, 9, PALETTE[ICE[(bar + phase) & 15]])
    text(image, x + 114, y + 80, "RASTER BARS", PALETTE[0], 3)

    raw = b"".join(b"\x00" + bytes(component for pixel in row for component in pixel) for row in image)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    OUT.parent.mkdir(exist_ok=True)
    OUT.write_bytes(png)


if __name__ == "__main__":
    main()
