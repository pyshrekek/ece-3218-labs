.def temp = r16

.cseg
.org 0x0000
        rjmp reset

reset:
        ldi  temp, 0b11111100
        out  DDRD, temp             ; PD7..PD2 outputs
        clr  temp
        out  PORTD, temp            ; all LEDs off
        out  DDRC, temp             ; PC0..PC5 inputs
        ldi  temp, 0b00111111
        out  PORTC, temp            ; enable pull-ups on PC0..PC5

main:
        in   temp, PINC             ; read switches
        andi temp, 0b00111111       ; keep only PC0..PC5
        lsl  temp                   ; PC0 -> PD1 position
        lsl  temp                   ; PC0 -> PD2 position
        out  PORTD, temp            ; show on LEDs
        rjmp main                   ; repeat forever