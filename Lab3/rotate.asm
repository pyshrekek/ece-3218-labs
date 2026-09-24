;=====================================================================
; Program 2 - Move a single lit LED from left to right, 200 ms per LED.
;             When it passes the right end, flash all LEDs, then restart.
; Target : ATmega328P @ 16 MHz (Arduino Uno), AVRASM2 syntax
;
; LED7 (PD7) is the leftmost LED, LED0 (PD0) the rightmost.
; "Left to right" therefore means shifting the bit pattern right (LSR).
;=====================================================================
.include "m328pdef.inc"

.equ STEP_MS  = 200                 ; time each LED is lit
.equ FLASHES  = 2                   ; how many times to flash at the end

.def temp  = r16
.def cnt   = r18                    ; delay_ms argument (milliseconds)
.def led   = r20                    ; current LED pattern
.def nflsh = r21

.org 0x0000
        rjmp reset

reset:
        ldi  temp, high(RAMEND)
        out  SPH, temp
        ldi  temp, low(RAMEND)
        out  SPL, temp

        clr  temp
        sts  UCSR0B, temp           ; free PD0/PD1 from the USART
        ldi  temp, 0xFF
        out  DDRD, temp             ; LEDs = outputs

restart:
        ldi  led, 0b10000000        ; start at the leftmost LED
step:
        out  PORTD, led
        ldi  cnt, STEP_MS
        rcall delay_ms
        lsr  led                    ; move one place to the right
        brne step                   ; still inside the 8 LEDs -> continue
        rcall flash_all             ; bit fell out -> boundary reached
        rjmp restart

;---------------------------------------------------------------------
; flash_all: all LEDs on/off FLASHES times, STEP_MS each phase
;---------------------------------------------------------------------
flash_all:
        ldi  nflsh, FLASHES
fa_loop:
        ldi  temp, 0xFF
        out  PORTD, temp
        ldi  cnt, STEP_MS
        rcall delay_ms
        clr  temp
        out  PORTD, temp
        ldi  cnt, STEP_MS
        rcall delay_ms
        dec  nflsh
        brne fa_loop
        ret

;---------------------------------------------------------------------
; delay_ms: busy-wait r18 milliseconds (1..255) at 16 MHz
;   inner loop : sbiw(2) + brne(2) = 4 cycles x 3999 - 1 = 15995
;   per ms     : 2 (ldi,ldi) + 15995 + 1 (dec) + 2 (brne) = 16000 cycles
;   total      : 16000*n + 7 cycles incl. ldi/rcall/ret (n=200 -> 200.0004 ms)
; uses r24, r25, r18
;---------------------------------------------------------------------
delay_ms:
dm_outer:
        ldi  r24, low(3999)
        ldi  r25, high(3999)
dm_inner:
        sbiw r24, 1
        brne dm_inner
        dec  cnt
        brne dm_outer
        ret