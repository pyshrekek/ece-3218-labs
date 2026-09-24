;=====================================================================
; Program 1 - Copy the DIP-switch settings to the LEDs (continuously)
; Target : ATmega328P @ 16 MHz (Arduino Uno), AVRASM2 syntax
;
; Wiring
;   LED0..LED7 : PD0..PD7  (Arduino D0..D7), active high, 330R to GND
;   SW0..SW5   : PC0..PC5  (Arduino A0..A5), switch to GND
;   SW6..SW7   : PB0..PB1  (Arduino D8..D9), switch to GND
;   Internal pull-ups enabled -> open switch reads 1, closed reads 0.
;   The value is inverted in software so that "switch ON" = "LED on".
;=====================================================================
.include "m328pdef.inc"

.def temp = r16
.def hi   = r17

.org 0x0000
        rjmp reset

reset:
        ldi  temp, high(RAMEND)     ; stack (needed for rcall)
        out  SPH, temp
        ldi  temp, low(RAMEND)
        out  SPL, temp

        clr  temp
        sts  UCSR0B, temp           ; make sure the USART doesn't own PD0/PD1

        ldi  temp, 0xFF
        out  DDRD, temp             ; PORTD = all outputs (LEDs)
        clr  temp
        out  PORTD, temp            ; LEDs off

        out  DDRC, temp             ; PORTC = inputs
        ldi  temp, 0x3F
        out  PORTC, temp            ; pull-ups on PC0..PC5
        cbi  DDRB, 0                ; PB0, PB1 inputs
        cbi  DDRB, 1
        sbi  PORTB, 0               ; pull-ups on PB0, PB1
        sbi  PORTB, 1

main:
        rcall read_switches         ; temp = SW7..SW0 (1 = ON)
        out   PORTD, temp           ; show them on the LEDs
        rjmp  main                  ; forever -> changes appear immediately

;---------------------------------------------------------------------
; read_switches: returns the 8 switches in temp (r16), 1 = switch ON
; uses r17
;---------------------------------------------------------------------
read_switches:
        in   temp, PINC
        andi temp, 0x3F             ; SW0..SW5 in bits 0..5
        in   hi, PINB
        andi hi, 0x03               ; SW6, SW7 in bits 0..1
        swap hi                     ; -> bits 4..5
        lsl  hi
        lsl  hi                     ; -> bits 6..7
        or   temp, hi
        com  temp                   ; closed switch = 0 V -> invert
        ret