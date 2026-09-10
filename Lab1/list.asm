	.cseg
	jmp main            ; Jump to first real instruction

main:
    clr r17             ; r17 = item counter, start at 0
    ldi XH, high(data)  ; Make X point to first byte of data
    ldi XL, low(data)

loop:
    ld r16, X+          ; Fetch next byte, bump index
    cpi r16, 0           ; Compare r16 to zero
    breq done            ; If r16 was zero, this was the terminator - stop
    ldi r18, 1           ; Load the constant 1 into r18
    add r17, r18          ; Add 1 to our running count
    rjmp loop            ; Go check the next byte

done:
    sts count, r17; Store result

fin:
    rjmp fin            ; Spin forever

; Data starts here (On this processor this is always 0x100)
	.dseg
data:  .byte 15         ; 15 item list
count: .byte 1          ; Space for result (total number of items)