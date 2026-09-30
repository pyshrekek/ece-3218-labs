.equ DELAY = 10                 ; delay count per step (1..255)

.macro DACOUT                   ; DACOUT reg : write reg to DAC channel A
    out  PORTD, @0
    cbi  PORTC, 0
    sbi  PORTC, 0
.endmacro

.equ TOP_LENGTH = 3
.equ BOT_LENGTH = 3

.cseg
.org 0x0000
    rjmp reset

reset:
    ldi  r16, high(RAMEND)
    out  SPH, r16
    ldi  r16, low(RAMEND)
    out  SPL, r16

    ; PC0 = WR must come up HIGH: set the PORT bit before the DDR bit
    sbi  PORTC, 0           ; PC0 = 1
    cbi  PORTC, 1           ; PC1 = 0 -> channel A (done once)
    sbi  DDRC, 0            ; PC0 output (goes out high, no glitch)
    sbi  DDRC, 1            ; PC1 output

    ldi  r16, 0xFF
    out  DDRD, r16          ; PD7..PD0 = data bus outputs
	clr  r17
	rjmp triangle

triangle:
        ldi  r21, DELAY         ; delay count (change this to change frequency)
        clr  r17

triangle_up:                        ; 0x00 .. 0xFE
        DACOUT r17              ; 5
        mov  r20, r21           ; 1
triangle_d1:
        dec  r20                ; 1  \
        brne triangle_d1            ; 2  /  N iterations = 3N - 1 cycles
        inc  r17                ; 1
        cpi  r17, 0xFF          ; 1
        brne triangle_up            ; 2      -> 9 + 3N cycles/step

triangle_down:                      ; 0xFF .. 0x01
        DACOUT r17              ; 5
        mov  r20, r21           ; 1
triangle_d2:
        dec  r20                ; 1  \
        brne triangle_d2            ; 2  /  3N - 1 cycles
        dec  r17                ; 1
        nop                     ; 1  pad to match 'up'
        brne triangle_down          ; 2      -> 9 + 3N cycles/step
        rjmp triangle_up