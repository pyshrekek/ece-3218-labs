/*
Loads the series 0x00, 0x01, 0x02 ... 0xFE, 0xFF, 0x00, 0x01 into the DAC. Sketch the
output waveform in your notebook. Estimate the period of this waveform. Other
commonly used waveforms are the triangle, square and sine wave. Modify the program
above so it is useful for generating a triangle wave. It should also be very easy to
generate a square wave at the same frequency; do so.
*/

.macro DACOUT                   ; DACOUT reg : write reg to DAC channel A
    out  PORTD, @0
    cbi  PORTC, 0
    sbi  PORTC, 0
.endmacro

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
	rjmp saw

saw:
	DACOUT r17              ; 1 + 2 + 2 = 5
	inc  r17                ; 1
	rjmp saw                ; 2          -> 8 cycles/step

triangle:
tri_up:                         ; 0x00 .. 0xFE
    DACOUT r17
    inc  r17
    cpi  r17, 0xFF
    brne tri_up
tri_down:                       ; 0xFF .. 0x01
    DACOUT r17
    dec  r17
    nop
    brne tri_down
    rjmp tri_up

square:
    ldi  r18, 0x00          ; low level
    ldi  r19, 0xFF          ; high level
sq_up:
    DACOUT r18
    inc  r17
    cpi  r17, 0xFF
    brne sq_up
sq_down:
    DACOUT r19
    dec  r17
    nop
    brne sq_down
    rjmp sq_up