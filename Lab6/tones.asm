; Lab 6, Program 2: play a scale on a piezo speaker on OC1A (PB1, Uno pin 9)
; Copies the tone periods into SRAM, then for each one: start a 50% duty
; wave with SETWAVE, wait 500 ms, stop the timer, wait 500 ms.

.DEF ZERO=R0

.equ NTONES = 10

.dseg
TONES:  .byte 2*NTONES      ; tone periods in timer clicks, low byte first

.cseg
.org 0x0000
        jmp RESET           ; reset
.org OC1Aaddr
        jmp TIM1_COMPA      ; Timer1 compare match A

.org INT_VECTORS_SIZE       ; code starts after the vector table
.include "wave.inc"

RESET:
        ; point the stack at the top of SRAM
        ldi r16,high(RAMEND)
        out SPH,r16
        ldi r16,low(RAMEND)
        out SPL,r16
        clr ZERO            ; keep a constant 0 in r0

        ; copy the period table from flash into TONES
        ldi ZL,low(TONETAB*2)
        ldi ZH,high(TONETAB*2)
        ldi XL,low(TONES)
        ldi XH,high(TONES)
        ldi r16,2*NTONES
COPY:
        lpm r17,Z+
        st X+,r17
        dec r16
        brne COPY

        ; play each tone
        ldi YL,low(TONES)
        ldi YH,high(TONES)
        ldi r20,NTONES      ; tones left
NEXTTONE:
        ld r24,Y+           ; pw
        ld r25,Y+
        ldi r23,DC50
        ldi r22,CLK_1
        rcall SETWAVE       ; tone on

        ldi r24,low(500)
        ldi r25,high(500)
        rcall waitnms

        sts TCCR1B,ZERO     ; clear the prescaler bits -> timer stops, tone off

        ldi r24,low(500)
        ldi r25,high(500)
        rcall waitnms

        dec r20
        brne NEXTTONE

DONE:
        rjmp DONE

; tone periods at prescaler 1: 16 MHz / f
TONETAB:
        .dw 61155           ; C4 261.63 Hz
        .dw 54485           ; D4 293.66 Hz
        .dw 48539           ; E4 329.63 Hz
        .dw 45815           ; F4 349.23 Hz
        .dw 40816           ; G4 392.00 Hz
        .dw 36364           ; A4 440.00 Hz
        .dw 32397           ; B4 493.88 Hz
        .dw 30578           ; C5 523.25 Hz
        .dw 27242           ; D5 587.33 Hz
        .dw 24270           ; E5 659.25 Hz

; 1 msec timer subroutine (exact; time includes call and return)
; wait1ms expends 16000 clock cycles.
; rcall wait1ms uses 3 clock cycles
; Therefore from the rcall in the calling program through the
; ret in the subroutine wait1ms expends
; 3+1+1+1+(3996*4)[in loop]+3[end of loop]+1+1+1+4 = 16000cc
; which at 16MHz (cc/s) equals 1ms.
wait1ms:
        ldi zh,0x0F         ; 1cc
        ldi zl,0x9D         ; 1cc
        clz                 ; 1cc
waitloop:                   ; countdown 0x0F9D = 3997dec
        sbiw z,1            ; 2cc
        brne waitloop       ; 2cc true, 1cc false
        nop                 ; 1cc
        nop                 ; 1cc
        nop                 ; 1cc
        ret                 ; 4cc

; waitnms: wait n ms
; load n into r24, r25
; r24, r25 and Z are restored before returning
; the compare ISR runs during the wait and stretches it slightly
waitnms:
        push r24            ; 2
        push r25            ; 2
        push zl             ; 2
        push zh             ; 2
        cp r24,ZERO         ; 1
        cpc r25,ZERO        ; 1
        breq waitnmsdone    ; 1 if n != 0
waitnmsloop:
        rcall wait1ms       ; 16000 total with rcall and ret
        sbiw r25:r24,1      ; 2
        brne waitnmsloop    ; 2 if taken, 1 if not
waitnmsdone:
        pop zh              ; 2
        pop zl              ; 2
        pop r25             ; 2
        pop r24             ; 2
        ret                 ; 4
