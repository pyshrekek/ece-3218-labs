;
; Lab2.asm
;
; Created: 9/10/2026 4:15:10 PM
; Author : ruker
;


; Replace with your application code
	.cseg
	jmp main; Jump to first real instruction
main:
	ldi zh,high(pmv1*2)
	ldi zl,low(pmv1*2)
	ldi xh,high(value1)
	ldi xl,low(value1)
	ldi r16,0x08
	rcall copybytes

copybytes:
	s


fin:
	rjmp fin;
; Data starts here (On this processor this is always 0x100)
	.dseg
data:.byte 5; Space for 5 bytes
sum:.byte 1; Space for result