; Lab 5, Program 2: alternating LEDs with a pin change interrupt
; Once a second the main loop flips PC0 (Uno A0, PCINT8). That change
; requests the PCINT1 interrupt, and its ISR flips the LED on PB0
; (Uno pin 8), so one LED is always on while the other is off.

.DEF ZERO=R0

.dseg                       ; SRAM variables
LEDON:  .byte 1             ; LED status ~0 ==> ON, 0 ==> OFF
PCLH:   .byte 1             ; Port C pin 0 status 1 ==> High, 0 ==> Low for PCINT0
COUNT:  .byte 4             ; number of times the interrupt routine was executed

; interrupt table
; this program requires RESET and PCINT1
.cseg
.org 0x0000
        jmp RESET           ; Reset Handler
.org PCI1addr
        jmp PC_INT1         ; PCINT1 Handler

.org INT_VECTORS_SIZE       ; code starts after the vector table
RESET:
        ; initialize stack pointer
        ldi r16,high(RAMEND)
        out SPH,r16
        ldi r16,low(RAMEND)
        out SPL,r16
        ; (R0)<-0x00 aliased to ZERO
        clr ZERO

        ; initialize variables
        ; LED status flag
        sts LEDON,ZERO      ; 0 ==> LED is not on
        ; number of times the ISR has been executed
        sts COUNT,ZERO      ; clear ISR count high byte
        sts COUNT+1,ZERO    ; clear ISR count upper middle byte
        sts COUNT+2,ZERO    ; clear ISR count lower middle byte
        sts COUNT+3,ZERO    ; clear ISR count low byte

        ; set up port B for output to LED
        sbi DDRB,0          ; bit 0 in Port B DDR <- 1, data direction out
        cbi PORTB,0         ; bit 0 in Port B <- 0, turn off the LED

        ; LED 2 on PC0 starts on
        sbi DDRC,0
        sbi PORTC,0
        ldi r16,1
        sts PCLH,r16        ; remember that PC0 is high

        ; let a change on PC0 (PCINT8) request PCINT1
        ; sbi/out can't reach PCICR and PCMSK1, so use sts
        ldi r16,(1<<PCIE1)  ; enable pin change group 1 (Port C)
        sts PCICR,r16
        ldi r16,(1<<PCINT8) ; only PC0 in that group
        sts PCMSK1,r16
        ldi r16,(1<<PCIF1)  ; clear a stale request (writing 1 clears it)
        out PCIFR,r16

        sei                 ; enable interrupts globally

; main loop: wait 1 s, then flip PC0, which triggers the interrupt
MAINLOOP:
        ldi r28,low(1000)   ; Y = 1000 ms
        ldi r29,high(1000)  ; 1000 needs 16 bits
        rcall waitNms

        ; flip PC0
        lds r16,PCLH
        tst r16
        brne PCHIGH         ; PC0 high -> low
        sbi PORTC,0         ; PC0 low -> high (LED 2 on)
        ldi r16,1
        rjmp PCSAVE
PCHIGH:
        cbi PORTC,0         ; LED 2 off
        clr r16
PCSAVE:
        sts PCLH,r16
        rjmp MAINLOOP

; PCINT1 ISR: count the interrupt, then toggle the LED on PB0
; saves SREG and every register it uses, since it interrupts the main loop
PC_INT1:
        push r16
        in r16,SREG
        push r16
        push r17
        push r24
        push r25
        push r26
        push r27

        ; load count of number of times ISR has been executed and increment it
        lds r27,COUNT       ; load the current ISR count, high byte
        lds r26,COUNT+1     ; load the current ISR count, upper middle byte
        lds r25,COUNT+2     ; load the current ISR count, lower middle byte
        lds r24,COUNT+3     ; load the current ISR count, low byte
        adiw r25:r24,1      ; increment the count
        brcc NOUHINC        ; if C==0, nothing to add to the upper half
        adiw r27:r26,1      ; else add one to upper half
NOUHINC:
        ; save the ISR execution count
        sts COUNT,r27       ; update the ISR count, high byte
        sts COUNT+1,r26     ; update the ISR count, upper middle byte
        sts COUNT+2,r25     ; update the ISR count, lower middle byte
        sts COUNT+3,r24     ; update the ISR count, low byte

        ; toggle the LED state
        lds r17,LEDON       ; get the LED status in r17
        tst r17             ; is it zero?
        brne ITSON          ; no? then the LED is on; go turn it off
        sbi PORTB,0         ; yes? then it's off; turn it on
        ldi r17,1           ; set the flag in r17
        rjmp DUNIT
ITSON:
        cbi PORTB,0         ; turn it off
        clr r17             ; clear the flag in r17
DUNIT:
        sts LEDON,r17       ; save r17 to the LED status flag

        ; restore in reverse order
        pop r27
        pop r26
        pop r25
        pop r24
        pop r17
        pop r16
        out SREG,r16
        pop r16
        reti

; waitNms: wait n ms
; load n (at least 1) into Y (r29:r28)
; Y ends at 0; Z is restored before returning
waitNms:
        push r30            ; wait1ms changes Z
        push r31
WNLOOP:
        rcall wait1ms       ; 16000 total with rcall and ret
        sbiw r29:r28,1
        brne WNLOOP
        pop r31
        pop r30
        ret

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
        sbiw r31:r30,1      ; 2cc
        brne waitloop       ; 2cc true, 1cc false
        nop                 ; 1cc
        nop                 ; 1cc
        nop                 ; 1cc
        ret                 ; 4cc
