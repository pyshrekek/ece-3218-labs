.equ STEP_MS   = 200                ; time per step (1..255 ms)
.equ LEDS_ALL  = 0b11111100         ; PD7..PD2
.equ LED_RIGHT = 0b10000000         ; PD7 = rightmost LED

.def temp    = r16
.def cnt     = r18                  ; delay_ms argument
.def pattern = r20                  ; pattern as shown on PORTD
.def last    = r21                  ; last switch value read

.org 0x0000
        rjmp reset

reset:
        ldi  temp, high(RAMEND)     ; stack pointer (needed for rcall)
        out  SPH, temp
        ldi  temp, low(RAMEND)
        out  SPL, temp

        ldi  temp, LEDS_ALL
        out  DDRD, temp             ; PD7..PD2 outputs
        clr  temp
        out  DDRC, temp             ; PORTC inputs
        ldi  temp, 0b00111111
        out  PORTC, temp            ; pull-ups on PC0..PC5
        nop                         ; input synchronizer delay before 1st read

        rcall read_switches         ; initial pattern
        mov  pattern, temp
        mov  last, temp

loop:
        out  PORTD, pattern         ; show the pattern
        ldi  cnt, STEP_MS
        rcall delay_ms              ; wait STEP_MS ms

        rcall read_switches         ; did the switches change?
        cp   temp, last
        breq rotate
        mov  last, temp             ; yes -> load the new pattern
        mov  pattern, temp
        rjmp loop

rotate:                             ; 6-bit circular rotate PD7 -> PD2
        lsr  pattern                ; every bit moves one LED to the left;
                                    ; the bit that was on PD2 lands in bit 1
        sbrc pattern, 1             ; did a bit fall off the left end (PD2)?
        ori  pattern, LED_RIGHT     ; yes -> wrap it around to PD7
        andi pattern, LEDS_ALL      ; clear bit 1 (and bit 0)
        rjmp loop

;---------------------------------------------------------------------
; read_switches: temp = switches aligned to PD7..PD2, 1 = switch ON
;   PC0..PC5 -> PD2..PD7 (shift left by 2)
;---------------------------------------------------------------------
read_switches:
        in   temp, PINC
        com  temp                   ; closed switch = 0 -> make it 1
        andi temp, 0b00111111       ; keep only PC0..PC5
        lsl  temp
        lsl  temp                   ; PC0..PC5 -> PD2..PD7
        ret

;---------------------------------------------------------------------
; delay_ms: busy-wait r18 milliseconds (1..255) at 16 MHz
;   one ms = 2 + (4*3999 - 1) + 1 + 2 = 16000 cycles
;   total  = 16000*n + 7 cycles incl. ldi, rcall, ret
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