	.cseg
	jmp main            ; Jump to first real instruction

main:
    clr r17             ; running max
	ldi r18, 0xFF       ; running min, start at highest possible byte value 
    ldi XH, high(data)  ; Make X point to first byte of data
    ldi XL, low(data)

loop:
    ld r16, X+          ; Fetch next byte, bump index
    cpi r16, 0           ; Compare r16 to zero
    breq done            ; If r16 was zero, this was the terminator - stop
    cp r16, r17          ; Compare current byte to running max
    brlo skipmax         ; If smaller, skip updating
    mov r17, r16         ; Otherwise, this is the new max
skipmax:
    cp r16, r18          ; Compare current byte to running min
    brsh skipmin         ; If bigger or equal, skip updating
    mov r18, r16         ; Otherwise, this is the new min
skipmin:
    rjmp loop            ; Go check the next byte


done:
    sts max, r17        ; Store max
    sts min, r18        ; Store min
    mov r19, r18         ; Copy min into r19
    lsl r19              ; r19 = min * 2 (shift left = multiply by 2)
    cp r17, r19          ; Compare max to (2 * min)
    brlo notgreater      ; If max < 2*min, skip
    ldi r20, 1           ; max > 2*min is true - store 1
    rjmp storeresult
notgreater:
    ldi r20, 0           ; max > 2*min is false - store 0
storeresult:
    sts result, r20      ; Store the true/false result

fin:
    rjmp fin            ; Spin forever

; Data starts here (On this processor this is always 0x100)
	.dseg
data:   .byte 15        ; 15 item list
max:    .byte 1         ; Largest value found
min:    .byte 1         ; Smallest value found
result: .byte 1         ; 1 if max > 2*min, else 0