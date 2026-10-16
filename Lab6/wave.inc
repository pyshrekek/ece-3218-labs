; wave.inc: rectangular wave on OC1A (PB1) using Timer1 output compare A
; Used by programs 1 and 2. The including program must put
;     jmp TIM1_COMPA
; at OC1Aaddr in its vector table.

; duty cycle codes for SETWAVE (r23)
; bits 1:0 = how far to shift pw right, bit 7 = invert the result
.equ DC12  = 0x03           ; 12.5% = pw >> 3
.equ DC25  = 0x02           ; 25%   = pw >> 2
.equ DC50  = 0x01           ; 50%   = pw >> 1
.equ DC75  = 0x82           ; 75%   = NOT 25%
.equ DC87  = 0x83           ; 87.5% = NOT 12.5%

; prescaler codes for SETWAVE (r22), the CS12:CS10 bits of TCCR1B
.equ CLK_1    = 1
.equ CLK_8    = 2
.equ CLK_64   = 3
.equ CLK_256  = 4
.equ CLK_1024 = 5

.dseg
HIGHCNT: .byte 2            ; OCR1A value for the high part (high width - 1)
LOWCNT:  .byte 2            ; OCR1A value for the low part (low width - 1)
.cseg

; SETWAVE: start a rectangular wave on OC1A
; r25:r24 = pw, period in timer clicks (at least 8)
; r23 = duty cycle code (DC12 ... DC87)
; r22 = prescaler code (CLK_1 ... CLK_1024)
; leaves r22-r25 unchanged and enables interrupts globally
SETWAVE:
        push r16
        push r17
        push r18
        push r19
        push r20
        push r21

        clr r16
        sts TCCR1B,r16      ; stop the timer while setting up

        ; part = pw >> shift
        movw r18,r24
        mov r20,r23
        andi r20,0x03       ; shift count
SW_SHIFT:
        lsr r19
        ror r18
        dec r20
        brne SW_SHIFT

        ; r19:r18 = high width = part, r17:r16 = low width = pw - part
        movw r16,r24
        sub r16,r18
        sbc r17,r19
        sbrs r23,7          ; inverted duty cycle?
        rjmp SW_SAVE
        movw r20,r16        ; yes -> swap high and low
        movw r16,r18
        movw r18,r20
SW_SAVE:
        ; in CTC mode each part lasts OCR1A + 1 clicks, so save width - 1
        subi r18,1
        sbci r19,0
        subi r16,1
        sbci r17,0
        sts HIGHCNT,r18
        sts HIGHCNT+1,r19
        sts LOWCNT,r16
        sts LOWCNT+1,r17

        ; PB1 is the output, starting high
        sbi DDRB,1
        sbi PORTB,1

        ; the first compare match ends the high part
        sts OCR1AH,r19      ; high byte first
        sts OCR1AL,r18
        clr r20
        sts TCNT1H,r20      ; count from 0
        sts TCNT1L,r20

        ; once COM1A is set, PB1 follows the OC1A bit, not PORTB,
        ; so force OC1A high: set-on-match mode + force compare,
        ; then switch to toggle mode (WGM11:10 = 0)
        ldi r20,(1<<COM1A1)|(1<<COM1A0)
        sts TCCR1A,r20
        ldi r20,(1<<FOC1A)
        sts TCCR1C,r20
        ldi r20,(1<<COM1A0) ; toggle OC1A on compare match
        sts TCCR1A,r20

        ldi r20,(1<<OCF1A)  ; clear a stale compare flag
        out TIFR1,r20
        ldi r20,(1<<OCIE1A) ; interrupt on compare match A
        sts TIMSK1,r20

        ; build TCCR1B in a register: CTC mode + prescaler
        ; writing it starts the timer, so do it last
        ldi r20,(1<<WGM12)
        or r20,r22
        sts TCCR1B,r20
        sei

        pop r21
        pop r20
        pop r19
        pop r18
        pop r17
        pop r16
        ret

; TIM1_COMPA: OC1A just toggled and TCNT1 was cleared
; load OCR1A with the width of the part that just started
TIM1_COMPA:
        push r16
        in r16,SREG
        push r16
        push r17

        sbis PINB,1         ; PB1 high -> low?
        rjmp TC_LOW
        lds r16,HIGHCNT     ; low -> high: time the high part
        lds r17,HIGHCNT+1
        rjmp TC_SET
TC_LOW:
        lds r16,LOWCNT      ; high -> low: time the low part
        lds r17,LOWCNT+1
TC_SET:
        sts OCR1AH,r17      ; high byte first
        sts OCR1AL,r16

        pop r17
        pop r16
        out SREG,r16
        pop r16
        reti
