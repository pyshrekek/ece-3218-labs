	.cseg
	jmp main            ; Jump to first real instruction

main:
    clr r17             ; running max
    ldi XH, high(data)  ; Make X point to first byte of data
    ldi XL, low(data)

loop:
    ld r16, X+          ; Fetch next byte, bump index
    cpi r16, 0           ; Compare r16 to zero
    breq done            ; If r16 was zero, this was the terminator - stop
    cp r16, r17          ; Compare current byte to running max
    brlo skip            ; If smaller, skip updating
    mov r17, r16         ; Otherwise, this is the new max
skip:
    rjmp loop            ; Go check the next byte


done:
    sts max, r17; Store result

fin:
    rjmp fin            ; Spin forever

; Data starts here (On this processor this is always 0x100)
	.dseg
data:  .byte 15         ; 15 item list
max: .byte 1          ; Space for result (total number of items)