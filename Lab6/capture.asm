; Program 3

.dseg
PREVCAP: .byte 2            ; ICR1 at the previous edge
PERIOD:  .byte 2            ; input period in clicks = output half period
ROLLED:  .byte 1            ; 1 if the timer rolled over during the last period

.cseg
.org 0x0000
        jmp RESET           ; reset
.org ICP1addr
        jmp TIM1_CAPT       ; Timer1 input capture
.org OC1Aaddr
        jmp TIM1_COMPA      ; Timer1 compare match A

.org INT_VECTORS_SIZE       ; code starts after the vector table
RESET:
        ; point the stack at the top of SRAM
        ldi r16,high(RAMEND)
        out SPH,r16
        ldi r16,low(RAMEND)
        out SPL,r16

        ; clear the variables
        clr r16
        sts PREVCAP,r16
        sts PREVCAP+1,r16
        sts PERIOD,r16
        sts PERIOD+1,r16
        sts ROLLED,r16

        cbi DDRB,0          ; PB0 = ICP1 input
        sbi DDRB,1          ; PB1 = OC1A output

        ldi r16,(1<<COM1A0) ; toggle OC1A on compare match, normal mode
        sts TCCR1A,r16

        ldi r16,(1<<ICF1)|(1<<OCF1A)    ; clear stale flags
        out TIFR1,r16
        ldi r16,(1<<ICIE1)|(1<<OCIE1A)  ; capture and compare A interrupts
        sts TIMSK1,r16

        ; noise canceller, capture on rising edge, clk/8 (starts the timer)
        ldi r16,(1<<ICNC1)|(1<<ICES1)|(1<<CS11)
        sts TCCR1B,r16
        sei

        ; the ISRs do the rest
SPIN:
        rjmp SPIN

; TIM1_CAPT: a rising edge arrived on ICP1
; PERIOD = ICR1 - previous ICR1
TIM1_CAPT:
        push r16
        in r16,SREG
        push r16
        push r17
        push r18
        push r19

        lds r16,ICR1L       ; low byte first
        lds r17,ICR1H
        lds r18,PREVCAP
        lds r19,PREVCAP+1
        sts PREVCAP,r16     ; this edge is the next one's previous edge
        sts PREVCAP+1,r17

        ; now - prev; borrow (C = 1) means now < prev, so the timer rolled
        ; over once. The 16-bit result already equals now + 65536 - prev,
        ; which is the right period, so only the flag is recorded.
        sub r16,r18
        sbc r17,r19
        clr r18             ; clr leaves C alone
        rol r18             ; r18 = rollover flag
        sts ROLLED,r18

        sts PERIOD,r16
        sts PERIOD+1,r17

        pop r19
        pop r18
        pop r17
        pop r16
        out SREG,r16
        pop r16
        reti

; TIM1_COMPA: OC1A just toggled; schedule the next toggle
; OCR1A = OCR1A + PERIOD. Adding to OCR1A instead of TCNT1 keeps the
; ISR's own latency from adding to every half period.
TIM1_COMPA:
        push r16
        in r16,SREG
        push r16
        push r17
        push r18
        push r19

        lds r16,OCR1AL
        lds r17,OCR1AH
        lds r18,PERIOD
        lds r19,PERIOD+1
        add r16,r18
        adc r17,r19
        sts OCR1AH,r17      ; high byte first
        sts OCR1AL,r16

        pop r19
        pop r18
        pop r17
        pop r16
        out SREG,r16
        pop r16
        reti
