# Variant audit

The supplied directory contained seven source files and two PRGs. Each source was assembled independently with ACME in a temporary audit directory. The source comments were treated as documentation only; the outcomes below are from the actual build commands.

| Variant | Result | Decision |
| --- | --- | --- |
| `ULTIMATE_EYECANDY_FINAL_PAL_r7f_SAFE_NOIRQ_SYS4096.s` | Builds cleanly; output is `CBM BASIC, SYS 4096`; PAL VICE autostart completed. | **Canonical source.** Self-contained and explicitly aligns `SYS 4096` with `$1000` entry. |
| `fixed_v7g_gfxboost.s` | Builds cleanly; output is `CBM BASIC, SYS 4608`. | Archived. Earlier buildable variant with debug heartbeat enabled. |
| `FIXED_v1_4_clean.s` | Fails ACME with duplicate-symbol errors at lines 450, 458, 473, and 490. | Archived as non-buildable source. |
| `v9_*_vicfix_acme.s` | Fails because `custom_charset_1bpp.bin` is absent. | Archived; dependency was not supplied. |
| `v9_*_vicfix_segfix.s` | Fails due to the same missing font plus unknown pseudo-opcodes. | Archived as non-buildable source. |
| `v10h_text_only_stable_nowarn_v2.s` | Fails because `custom_charset_1bpp.bin` is absent. | Archived; matching PRG retained separately. |
| `v10k4c_chargfx_safe_loudsid_clean.s` | Fails because `custom_charset_1bpp.bin` is absent. | Archived; dependency was not supplied. |

## Prebuilt PRGs

The supplied `deepseek_asm.prg` identifies as `SYS 4608`; `deepseek_asm_20251009_v10h_text_only_stable_nowarn_v2.prg` identifies as `SYS 6144`. Both are retained under `archive/prebuilt/` because the source set does not provide a verified, fully reproducible source match for them.

## Canonical validation

The canonical source was assembled with:

```sh
acme -f cbm -o c64-horizon-warp.prg src/c64-horizon-warp.s
```

It produced a `CBM BASIC, SYS 4096` program. A PAL VICE run completed autostart and reached its normal cycle-limited exit while saving the screenshot tracked in `assets/`.
