.equ STEP_MS   = 200                ; time each LED is lit (1..255 ms)
.equ FLASHES   = 1                  ; number of flashes at the boundary
.equ DIR_BIT   = 0                  ; direction switch on PC0
.equ LEDS_ALL  = 0b11111100         ; PD7..PD2
.equ LED_LEFT  = 0b00000100         ; PD2 = leftmost LED
.equ LED_RIGHT = 0b10000000         ; PD7 = rightmost LED

.def temp  = r16
.def cnt   = r18                    ; delay_ms argument
.def led   = r20                    ; current LED pattern
.def nflsh = r21

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

        rcall start_pos             ; pick starting end from the switch

step:
        out  PORTD, led             ; light the current LED
        ldi  cnt, STEP_MS
        rcall delay_ms              ; wait STEP_MS ms
        sbic PINC, DIR_BIT          ; PC0 = 0 (switch ON)? skip next
        rjmp go_left                ; PC0 = 1 (switch OFF) -> right to left

go_right:                           ; left to right: PD2 -> PD7
        lsl  led
        brne step                   ; after PD7 the bit falls out -> 0
        rjmp boundary

go_left:                            ; right to left: PD7 -> PD2
        lsr  led
        cpi  led, LED_LEFT
        brsh step                   ; still at PD2 or higher -> continue

boundary:                           ; light left the 6 LEDs
        rcall flash_all
        rcall start_pos
        rjmp step

;---------------------------------------------------------------------
; start_pos: led = PD2 if moving right, PD7 if moving left
;---------------------------------------------------------------------
start_pos:
        ldi  led, LED_LEFT          ; assume left to right: start at PD2
        sbic PINC, DIR_BIT          ; switch ON -> keep PD2
        ldi  led, LED_RIGHT         ; switch OFF -> start at PD7
        ret

;---------------------------------------------------------------------
; flash_all: all LEDs on then off, FLASHES times, STEP_MS per phase
;---------------------------------------------------------------------
flash_all:
        ldi  nflsh, FLASHES
fa_loop:
        ldi  temp, LEDS_ALL
        out  PORTD, temp            ; all on
        ldi  cnt, STEP_MS
        rcall delay_ms
        clr  temp
        out  PORTD, temp            ; all off
        ldi  cnt, STEP_MS
        rcall delay_ms
        dec  nflsh
        brne fa_loop
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