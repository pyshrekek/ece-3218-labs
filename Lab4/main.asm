.macro DACOUT                   ; DACOUT reg : write reg to DAC channel A
    out  PORTD, @0
    cbi  PORTC, 0
    sbi  PORTC, 0
.endmacro

.equ TOP_LENGTH = 200
.equ BOT_LENGTH = 200

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
	rjmp trapezoid

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

trapezoid:
    ldi r21, TOP_LENGTH
    ldi r22, BOT_LENGTH
    clr r17
    ; all sections should sum to 9 clock cycles

trap_bot_init:
    mov r20, r22 ; load bottom length

trap_bot:
    DACOUT r17
    nop
    dec r20
    brne trap_bot

trap_up:
    inc r17
    DACOUT r17
    cpi r17, 0xFE
    brne trap_up

    inc r17
    mov r20, r21

trap_top:
    DACOUT r17
    nop
    dec r20
    brne trap_top

trap_down:
    dec r17
    DACOUT r17
    cpi r17, 0x01
    brne trap_down
    
    dec r17
    rjmp trap_bot_init