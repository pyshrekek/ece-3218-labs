; Every second the main loop toggles Port C pin 0 (Uno A0, PCINT8).
; That pin change triggers the PCINT1 interrupt, whose ISR toggles
; the LED on Port B pin 0 (Uno digital 8). The two LEDs alternate:
; one is on while the other is off.

.DEF ZERO=R0

.dseg                       ; SRAM variables
LEDON:  .byte 1             ; PB0 LED status  ~0 ==> ON, 0 ==> OFF   (0x0100)
PCLH:   .byte 1             ; PC0 pin status   1 ==> High, 0 ==> Low (0x0101)
COUNT:  .byte 4             ; number of times the ISR ran, high byte first (0x0102-0x0105)

; interrupt vector table
; this program requires RESET and PCINT1
.cseg
.org 0x0000
        jmp RESET           ; Reset handler
.org PCI1addr               ; 0x0008: pin change interrupt 1 (Port C, PCINT8-14)
        jmp PC_INT1         ; PCINT1 handler

.org INT_VECTORS_SIZE       ; start the program after the whole vector table
RESET:
        ; initialize stack pointer
        ldi r16,high(RAMEND)
        out SPH,r16
        ldi r16,low(RAMEND)
        out SPL,r16
        ; (R0)<-0x00 aliased to ZERO
        clr ZERO

        ; initialize variables
        sts LEDON,ZERO      ; PB0 LED starts off
        sts COUNT,ZERO      ; clear ISR count (all 4 bytes)
        sts COUNT+1,ZERO
        sts COUNT+2,ZERO
        sts COUNT+3,ZERO

        ; Port B pin 0: output, LED 1 off
        sbi DDRB,0          ; PB0 is an output
        cbi PORTB,0         ; PB0 low ==> LED 1 off

        ; Port C pin 0: output, LED 2 on
        sbi DDRC,0          ; PC0 is an output
        sbi PORTC,0         ; PC0 high ==> LED 2 on
        ldi r16,1
        sts PCLH,r16        ; record that PC0 is high

        ; set up pin change interrupt on PCINT8 (= PC0)
        ; PCICR and PCMSK1 are in extended I/O space, so use sts (sbi can't reach them)
        ldi r16,(1<<PCIE1)  ; enable pin change interrupt group 1 (Port C)
        sts PCICR,r16
        ldi r16,(1<<PCINT8) ; within group 1, only PCINT8 (PC0) triggers it
        sts PCMSK1,r16
        ldi r16,(1<<PCIF1)  ; clear any pending PCINT1 flag (write 1 to clear)
        out PCIFR,r16

        sei                 ; enable interrupts globally

; main loop: wait 1 second, toggle PC0, repeat
; toggling PC0 is what generates the pin change interrupt
MAINLOOP:
        ldi r28,low(1000)   ; n = 1000 ms in Y (r29:r28)
        ldi r29,high(1000)  ; 1000 > 255, so a 16-bit counter is needed
        rcall waitNms

        ; toggle PC0 using the PCLH status variable
        lds r16,PCLH        ; get PC0 status
        tst r16             ; is it low?
        brne PCHIGH         ; no? it's high, go drive it low
        sbi PORTC,0         ; yes? drive PC0 high (LED 2 on)
        ldi r16,1           ; status <- high
        rjmp PCSAVE
PCHIGH:
        cbi PORTC,0         ; drive PC0 low (LED 2 off)
        clr r16             ; status <- low
PCSAVE:
        sts PCLH,r16        ; save PC0 status
        rjmp MAINLOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ISR for pin change interrupt 1 (PCINT1)
; Runs once per edge on PC0, i.e. once per toggle in the main loop.
; Saves every register it uses plus SREG, because the main loop is
; busy (r16, the Z flag, the delay counters) when the interrupt hits.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PC_INT1:
        push r16
        in r16,SREG         ; save status register
        push r16
        push r17
        push r24
        push r25
        push r26
        push r27

        ; increment 32-bit ISR execution count
        lds r27,COUNT       ; high byte
        lds r26,COUNT+1     ; upper middle byte
        lds r25,COUNT+2     ; lower middle byte
        lds r24,COUNT+3     ; low byte
        adiw r25:r24,1      ; increment lower half
        brcc NOUHINC        ; if C==0, nothing to carry into the upper half
        adiw r27:r26,1      ; else add one to upper half
NOUHINC:
        sts COUNT,r27
        sts COUNT+1,r26
        sts COUNT+2,r25
        sts COUNT+3,r24

        ; toggle the PB0 LED state
        lds r17,LEDON       ; get LED status
        tst r17             ; is it zero?
        brne ITSON          ; no? LED is on; go turn it off
        sbi PORTB,0         ; yes? it's off; turn it on
        ldi r17,1           ; set the flag
        rjmp DUNIT
ITSON:
        cbi PORTB,0         ; turn it off
        clr r17             ; clear the flag
DUNIT:
        sts LEDON,r17       ; save LED status

        pop r27
        pop r26
        pop r25
        pop r24
        pop r17
        pop r16
        out SREG,r16        ; restore status register
        pop r16
        reti

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; n msec delay
; Input: Y (r29:r28) = n, number of milliseconds (n must be >= 1;
;        n = 0 would wrap around to 65536 ms)
; Uses:  Z (saved/restored), Y (counted down to 0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
waitNms:
        push r30            ; wait1ms uses Z, so save it
        push r31
WNLOOP:
        rcall wait1ms       ; wait 1 ms
        sbiw r29:r28,1      ; n <- n - 1
        brne WNLOOP         ; repeat until n == 0
        pop r31
        pop r30
        ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1 msec timer subroutine (exact; time includes call and return)
; 3+1+1+1+(3996*4)+3+1+1+1+4 = 16000  = 1 ms at 16 MHz
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wait1ms:
        ldi zh,0x0F         ; 1
        ldi zl,0x9D         ; 1
        clz                 ; 1
waitloop:                   ; countdown 0x0F9D = 3997 dec
        sbiw r31:r30,1      ; 2
        brne waitloop       ; 2 true, 1 false
        nop                 ; 1
        nop                 ; 1
        nop                 ; 1
        ret                 ; 4