.macro DACOUT                   ; DACOUT reg : write reg to DAC channel A
    out  PORTD, @0
    cbi  PORTC, 0
    sbi  PORTC, 0
.endmacro

.equ SKIP = 2                   ; table step per sample (1..31)

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
	rjmp sine_skip

sine:
    ldi  r19, 0x80          ; XOR mask: 0x80 = positive half, 0x7F = negative half
    ldi  r24, 0x00          ; PORTC value: WR low  (PC1 = 0 -> channel A)
    ldi  r25, 0x01          ; PORTC value: WR high (PC1 = 0 -> channel A)

sine_half:
    ldi  ZL, low(sine_table*2)    ; Z -> start of table (byte address)
    ldi  ZH, high(sine_table*2)
    ldi  r18, 32                ; 32 samples per half-cycle

sine_loop:
    lpm  r17, Z+            ; 3  fetch T[n], advance pointer
    eor  r17, r19           ; 1  -> 128+T or 127-T
    out  PORTD, r17         ; 1  data onto bus
    out  PORTC, r24         ; 1  WR low
    out  PORTC, r25         ; 1  WR high -> latched
    dec  r18                ; 1
    brne sine_loop          ; 2          -> 10 cycles/sample

    com  r19                ; swap halves: 0x80 <-> 0x7F
    rjmp sine_half

;------------------------------------------------ sine with variable step
sine_skip:
        ldi  r19, 0x80          ; XOR mask: positive half
        ldi  r24, 0x00          ; PORTC: WR low,  channel A
        ldi  r25, 0x01          ; PORTC: WR high, channel A
        ldi  r22, SKIP          ; step size (change at runtime to change frequency)
        ldi  ZH, high(sine_table*2)
        ldi  ZL, low(sine_table*2)    ; = 0x00 because the table is aligned

ss_loop:
        lpm  r17, Z             ; 3  fetch T[index]
        eor  r17, r19           ; 1  -> 128+T or 127-T
        out  PORTD, r17         ; 1
        out  PORTC, r24         ; 1  WR low
        out  PORTC, r25         ; 1  WR high
        add  ZL, r22            ; 1  index += K
        cpi  ZL, 32             ; 1  past end of half-cycle?
        brlo ss_loop            ; 2      -> 11 cycles/sample

        subi ZL, 32             ; wrap index, keeping the remainder
        com  r19                ; switch halves: 0x80 <-> 0x7F
        rjmp ss_loop            ; wrap samples take 14 cycles



.org 0x0200                     ; word 0x200 = byte 0x400 -> low byte 0x00
sine_table:
    .db   0,  12,  25,  37,  49,  60,  71,  81
    .db  90,  98, 106, 112, 117, 122, 125, 126
    .db 127, 126, 125, 122, 117, 112, 106,  98
    .db  90,  81,  71,  60,  49,  37,  25,  12