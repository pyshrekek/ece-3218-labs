;
; Lab1.asm
;
; Created: 9/7/2026 2:41:38 PM
; Author : ruker
;


;	
	.cseg
	jmp main; Jump to first real instruction
main:
	clr r0; Clear accumulator
	ldi r16,5; Set the loop counter
	ldi XH,high(data); Make X point to first byte of data
	ldi XL,low(data)
loop:
	ld r1,X+; Fetch next byte, bump index
	add r0,r1; Add byte to accumulator
	dec r16; Decrement loop counter
	brne loop; Loop if we are not done yet
	st X+,r0; Store result
fin:
	rjmp fin;
; Data starts here (On this processor this is always 0x100)
	.dseg
data:.byte 5; Space for 5 bytes
sum:.byte 1; Space for result