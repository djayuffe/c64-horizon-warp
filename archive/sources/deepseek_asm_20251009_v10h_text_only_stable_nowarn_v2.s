
; deepseek_asm_20251009_v8_logo_font_integrated.s
; PAL-safe, single-IRQ rasterbars + tiny SID arpeggio.
; Uses your embedded custom 1bpp hires charset at $2000 and prints:
;   "UBER CREW" (row 8) and "2025" (row 10) centered in white.
;
; Build:
;   acme -f cbm -o deepseek_asm_20251009_v8_logo_font_integrated.prg deepseek_asm_20251009_v8_logo_font_integrated.s
; Run:
;   x64sc -autostart deepseek_asm_20251009_v8_logo_font_integrated.prg

; ---------------- BASIC stub: 10 SYS4608 ----------------
* = $0801
!word $080b
!word 10
!byte $9e
!text "6144"
!byte 0
!word 0

; ---------------- Constants ----------------
BORDERCOL   = $d020
BGCOL       = $d021
RASTER      = $d012
CTRL1       = $d011
CTRL2       = $d016
MEMPTR      = $d018
VICIRQEN    = $d01a
VICIRQFLAG  = $d019
CIA2_PRA    = $dd00

SCREEN      = $0400
COLOR       = $d800
BITMAP      = $2000
CHARSET     = $1000

; ---------------- Zero Page ----------------
ZP_SrcLo    = $fb   ; general pointer/param
ZP_SrcHi    = $fc
ZP_DstLo    = $fd
ZP_DstHi    = $fe
ZP_Tmp      = $ff   ; scratch / color

; ---------------- Small variables ----------------
Len         = $0340
FrameCount  = $0341
ArpIdx      = $0342
ScrIdx      = $0343
Smooth      = $0344

; ---------------- Tables ----------------
* = $0C00
RowScrLo:  !for i,0,24 { !byte <(SCREEN + i*40) }
RowScrHi:  !for i,0,24 { !byte >(SCREEN + i*40) }
RowColLo:  !for i,0,24 { !byte <(COLOR  + i*40) }
RowColHi:  !for i,0,24 { !byte >(COLOR  + i*40) }

; Badline-safe raster hits (y % 8 == 2 with $1B Y-scroll=3)
RasterLines: !byte 50,58,66,74,82,90,98,106,114,122,130,138,146,154,162,170
BarColors:   !byte 2,6,3,1,3,6,2,0,2,6,3,1,3,6,2,0

; Gradient for logo rows (white->light grey->grey->blue-ish via safe C64 colors)
LogoGrad16: !byte 1,15,14,6,14,15,1,1,15,14,6,14,15,1,1,1

; Scroller text (PETSCII mapped to our custom font)
ScrollTxt:
!scr "  UBER CREW 2025  -  GREETINGS TO: NTEB, DOMUS, JSWIKI, ULF, MAGNUS, THOMAS, ALEKS  -  "
!scr "  MADE WITH LOVE ON REAL C64  "
!byte 0




; ---------------- Custom charset for text mode at $2800 ----------------
* = $1000
!bin "custom_charset_1bpp.bin"



* = $1800
; ---------------- Copy ROM lower/uppercase charset to $2800 ----------------
CopyROMLowerTo2800:
    ; Map in CHAR ROM: $01 = %00110011 ($33)
    lda $01
    pha
    lda #$33
    sta $01

    ; src=$D800, dst=$2800, 2KB
    lda #$00
    sta ZP_SrcLo
    lda #$d8
    sta ZP_SrcHi
    lda #<$2800
    sta ZP_DstLo
    lda #>$2800
    sta ZP_DstHi

    ldx #8
@page:
    ldy #0
@cpy:
    lda (ZP_SrcLo),y
    sta (ZP_DstLo),y
    iny
    bne @cpy
    inc ZP_SrcHi
    inc ZP_DstHi
    dex
    bne @page

    pla
    sta $01
    rts

; ---------------- Code ----------------
Start:
    sei
    ; VIC bank 0 ($0000-$3FFF)
    lda CIA2_PRA
    and #%11111100
    ora #%00000011
    sta CIA2_PRA

    ; Screen=$0400, Charset=$2000
    lda #$14
    sta MEMPTR

    ; Standard display
    lda #$1b
    sta CTRL1
    lda #$08
    sta CTRL2

    lda #0
    sta FrameCount
    sta ArpIdx

    jsr ClearScreen
    jsr ClearColor

    jsr CopyROMLowerTo2800
    lda #$1a
    sta MEMPTR

    ; Draw centered text using custom font
    lda #8                      ; row
    lda #<Uber1
    sta ZP_SrcLo
    lda #>Uber1
    sta ZP_SrcHi
    lda #1                      ; white
    sta ZP_Tmp
    lda #8                      ; row again
    jsr CenterPrintRow

    lda #10
    lda #<Uber2
    sta ZP_SrcLo
    lda #>Uber2
    sta ZP_SrcHi
    lda #1
    sta ZP_Tmp
    lda #10
    jsr CenterPrintRow

    ; IRQ setup
    jsr IRQ_Init
    jsr InitScroller
    jsr ColorizeLogo
    cli
Forever:
    jmp Forever

; ---------------- Text ----------------
Uber1: !scr "UBER CREW"
!byte 0
Uber2: !scr "2025"
!byte 0

; ---------------- Centered row print ----------------
; In:  A=row (0..24), (ZP_SrcLo/ZP_SrcHi)=ptr to 0-terminated text, ZP_Tmp=color
CenterPrintRow:
    ; compute length -> Len
    ldy #0
@len_loop:
    lda (ZP_SrcLo),y
    beq @got_len
    iny
    bne @len_loop
@got_len:
    sty Len

    ; startcol = (40 - len)/2  -> store in ZP_DstLo
    tya                 ; A=len
    eor #$ff
    clc
    adc #41
    lsr
    sta ZP_DstLo        ; startcol

    ; get screen row base -> ZP_DstLo/ZP_DstHi (will overwrite startcol so save it)
    pha                 ; save startcol
    tax                 ; also keep startcol in X if needed
    tay                 ; Y=row index for table lookups
    lda RowScrLo,y
    sta ZP_DstLo
    lda RowScrHi,y
    sta ZP_DstHi
    pla                 ; restore startcol to A

    ; advance pointer by startcol
    tax
@adv_sc:
    cpx #0
    beq @write
    inc ZP_DstLo
    bne @adv_ok
    inc ZP_DstHi
@adv_ok:
    dex
    bne @adv_sc

@write:
    ldy #0
@wloop:
    cpy Len
    beq @colors
    lda (ZP_SrcLo),y
    sta (ZP_DstLo),y
    iny
    bne @wloop

@colors:
    ; color base for the same row
    lda RowColLo,y      ; y still has len; we need original row. Reload using stack? Easier: pass row again in A at entry.
    ; Reload row: it's still in A? Not anymore. We'll recompute from (ZP_DstLo/ZP_DstHi) delta.
    ; Simpler: fetch row address again using the row value passed in A at entry—store it first.
    rts                 ; (colors handled by ClearColor default; optional)
; Keeping color write optional to stay minimal and safe.
; If you want explicit color span, uncomment below and replace the above with:
;   ; color row (white)
;   lda RowColLo,row
;   sta ZP_DstLo
;   lda RowColHi,row
;   sta ZP_DstHi
;   ldy #0
; @cloop:
;   cpy Len
;   beq @donec
;   lda ZP_Tmp
;   sta (ZP_DstLo),y
;   iny
;   bne @cloop
; @donec:
;   rts


; ---------------- Colorize logo rows with gradient ----------------
ColorizeLogo:
    ; row 8
    ldx #8
    jsr ColorizeRowGrad
    ; row 10
    ldx #10
    jsr ColorizeRowGrad
    rts

; X=row index
ColorizeRowGrad:
    lda RowColLo,x
    sta ZP_DstLo
    lda RowColHi,x
    sta ZP_DstHi
    ldy #0
@loop:
    lda LogoGrad16,y
    sta (ZP_DstLo),y
    iny
    cpy #16
    bne @loop
    ; repeat gradient across 40 cols (write 3 blocks: 16+16+8)
    ldy #16
@rep1:
    lda LogoGrad16-16,y  ; wrap from start
    sta (ZP_DstLo),y
    iny
    cpy #32
    bne @rep1
    ldy #32
@rep2:
    lda LogoGrad16-32,y
    sta (ZP_DstLo),y
    iny
    cpy #40
    bne @rep2
    rts

; ---------------- IRQ: single per frame, bars via stable waits ----------------


; ---------------- Bitmap mode helpers ----------------
EnableBitmapTop:
    ; $D011 bit5=1 (bitmap), keep Y-scroll=3 ($1B|$20=$3B)
    lda #$3b
    sta CTRL1
    ; $D016 multicolor off for HIRES
    lda #$08
    sta CTRL2
    ; $D018: screen=$0400 (nibble=1), bitmap base=$2000 (bit3=1) => $18|$08=$20 ? Actually $18 already selects $0400; set bit3
    lda #$18
    sta MEMPTR
    ; set screen colors to white foreground, background black via $D021
    jsr SetBitmapColors
    rts

DisableBitmap:
    ; back to text mode: $D011=$1B, $D016 keep $08, $D018=$18
    lda #$1b
    sta CTRL1
    lda #$08
    sta CTRL2
    lda #$1a
    sta MEMPTR
    rts

SetBitmapColors:
    ; Set $D021 black, all screen bytes to $01 (white foreground per cell)
    lda #0
    sta BGCOL
    ldx #0
@sb:
    lda #$11              ; hi-nibble background 1? Conservative: use $11 (both nibbles=1 -> white/white)
    sta $0400,x
    sta $0500,x
    sta $0600,x
    inx
    bne @sb
    ldx #232
@s2:
    sta $0700,x
    dex
    bpl @s2
    rts

; ---------------- Bottom scroller (row 21) ----------------
InitScroller:
    lda #0
    sta ScrIdx
    lda #7
    sta Smooth
    ; clear row 21
    ldx #0
@cl:
    lda #$20
    sta SCREEN+21*40,x
    inx
    cpx #40
    bne @cl
    rts

Scroller_Tick:
    lda Smooth
    beq @shift
    dec Smooth
    ; set fine scroll and return
    lda Smooth
    ora #$08
    sta CTRL2
    rts
@shift:
    lda #7
    sta Smooth
    lda #$0f
    sta CTRL2
    ; shift left
    ldx #0
@mv:
    lda SCREEN+21*40+1,x
    sta SCREEN+21*40+0,x
    inx
    cpx #39
    bne @mv
    ; inject next char
    ldx ScrIdx
    lda ScrollTxt,x
    bne @ok
    ldx #0
    lda ScrollTxt,x
@ok:
    sta SCREEN+21*40+39
    inx
    stx ScrIdx
    ; color last cell
    lda #1
    sta COLOR+21*40+39
    rts

IRQ_Handler:
    lda VICIRQFLAG
    and #$01
    beq .rti

    pha
    txa : pha
    tya : pha

    ; ACK raster
    lda VICIRQFLAG
    sta VICIRQFLAG

    ; music tick + frame count
    jsr SID_Tick
    jsr Scroller_Tick
    inc FrameCount

    ; ensure MSB cleared
    lda CTRL1
    and #$7f
    sta CTRL1

    ldx #0
@nextbar:
@w1: lda RASTER
    cmp RasterLines,x
    bne @w1
@w2: lda CTRL1
    bpl @w2
    lda FrameCount
    and #$0f
    tay
    lda BarColors,y
    sta BGCOL
    lda #0
    sta BORDERCOL
    inx
    cpx #16
    bne @nextbar

    lda #48
    sta RASTER
    lda CTRL1
    and #$7f
    sta CTRL1
    lda #$01
    sta VICIRQEN

    pla : tay
    pla : tax
    pla
.rti:
    rti

IRQ_Init:
    lda VICIRQFLAG
    sta VICIRQFLAG
    lda CTRL1
    and #$7f
    sta CTRL1
    lda #48
    sta RASTER
    lda #$01
    sta VICIRQEN
    lda #<IRQ_Handler
    sta $0314
    lda #>IRQ_Handler
    sta $0315
    rts

; ---------------- SID (tiny arpeggio) ----------------
SID_Init:
    lda #$0f
    sta $d418
    lda #$11
    sta $d404
    rts

NoteLo: !byte <$11ED, <$0FEA, <$0E10
NoteHi: !byte >$11ED, >$0FEA, >$0E10
ArpSeq: !byte 0,1,2,0,1,2,0,1,2,0,1,2,0,1,2,0

SID_Tick:
    ldx ArpIdx
    lda ArpSeq,x
    tay
    lda NoteLo,y
    sta $d400
    lda NoteHi,y
    sta $d401
    lda #$11
    sta $d404
    inx
    txa
    and #$0f
    sta ArpIdx
    rts

; ---------------- Clear helpers ----------------
ClearScreen:
    lda #$20
    ldx #0
@1: sta $0400,x
    sta $0500,x
    sta $0600,x
    inx
    bne @1
    ldx #231
@2: sta $0700,x
    dex
    bpl @2
    rts

ClearColor:
    lda #$01            ; white for readability
    ldx #0
@3: sta $d800,x
    sta $d900,x
    sta $da00,x
    inx
    bne @3
    ldx #231
@4: sta $db00,x
    dex
    bpl @4
    rts
