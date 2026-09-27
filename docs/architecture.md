# Architecture notes

## Boot path

The PRG loads at `$0801` and contains a tokenized BASIC line that executes `SYS 4096`. The canonical source places `Start` first at `$1000`, so the loader and machine-code entry agree.

`Start` performs the following sequence:

1. Disable maskable interrupts with `SEI` and reset the stack.
2. Disable/acknowledge CIA and VIC interrupt sources.
3. Point the KERNAL NMI vector at a harmless `RTI` stub.
4. Select VIC bank 0, screen RAM at `$0400`, and the RAM character set at `$2000`.
5. Clear screen and colour RAM, copy the ROM character set, then apply the custom character modifications.
6. Initialize state, sprite data, logo, and borders.
7. Enter `MainLoop` without executing `CLI`; this is intentionally a no-IRQ design.

## Memory map

| Address | Use |
| --- | --- |
| `$0801` | BASIC `SYS 4096` loader. |
| `$0900` | Lookup tables and text data. |
| `$1000` | `Start`, frame loop, and effect routines. |
| `$0400-$07e7` | 40 × 25 screen RAM. |
| `$07f8-$07ff` | Sprite pointers in the screen page. |
| `$2000-$27ff` | RAM character set copied from C64 ROM and modified for the effect. |
| `$2800` | Sprite data. |
| `$d800-$dbe7` | Colour RAM. |
| `$033a-$0348` | Small runtime state values. |

## Frame timing

`WaitFrameStart` first observes the high PAL raster range, then waits until the raster counter wraps to zero with the high raster bit clear. This prevents a low-byte-only `$D012` observation at PAL line 256 from being mistaken for line 0.

`MainLoop` runs one foreground frame at a time:

| Stage | Raster position | Work |
| --- | --- | --- |
| Frame sync | wrap to 0 | Advance the frame counter and scroller. |
| Top section | 50 | Cycle border/logo shine. |
| Mid section | 120 | Update sprites and colour wave. |
| Plasma | 170 | Update plasma colours. |
| Raster bars | 220 | Draw the lower visual treatment. |

`WaitRasterA` handles a missed target by waiting for the next frame rather than immediately continuing in the wrong frame. All scheduled targets are below 256; this matches the PAL-safe source design.

## Effect ownership

Because the canonical release keeps interrupts disabled, the main loop owns all frame state. `FrameCount`, scroller position, colour phase, logo phase, plasma phase, and sprite state are advanced only from this loop. `KeyPoll` intentionally does nothing in the safe release.

This means a future interactive or IRQ-based variant must be designed as a separate change: it must establish safe ownership for state currently updated only by the foreground loop.

## Correctness notes

The logo renderer writes colors directly to the intended `COLOR` rows while
preserving its text index. This avoids aliasing a temporary index onto the high
byte of a zero-page pointer, which can otherwise redirect writes outside color
RAM. The CIA2 VIC-bank select pins are also explicitly configured as outputs;
the selected bank is not left dependent on prior KERNAL state.
