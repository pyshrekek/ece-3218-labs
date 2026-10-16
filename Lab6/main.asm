; Lab 6, Program 1: rectangular wave on OC1A (PB1, Uno pin 9)
; Calls SETWAVE once with a 440 Hz period and the duty cycle in DUTY,
; then waits while the Timer1 compare ISR generates the wave.

.cseg
.org 0x0000
        jmp RESET           ; reset
.org OC1Aaddr
        jmp TIM1_COMPA      ; Timer1 compare match A

.org INT_VECTORS_SIZE       ; code starts after the vector table
.include "wave.inc"

.equ PW   = 36364           ; 440 Hz at prescaler 1
.equ DUTY = DC50            ; DC12, DC25, DC50, DC75 or DC87

RESET:
        ; point the stack at the top of SRAM
        ldi r16,high(RAMEND)
        out SPH,r16
        ldi r16,low(RAMEND)
        out SPL,r16

        ldi r24,low(PW)
        ldi r25,high(PW)
        ldi r23,DUTY
        ldi r22,CLK_1
        rcall SETWAVE

        ; the ISR does the rest
SPIN:
        rjmp SPIN
