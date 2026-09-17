;
; Lab2.asm
;
; Created: 9/10/2026 4:15:10 PM
; Author : ruker
;
.cseg
.org 0x0000
        rjmp    reset               ; jmp works too, but rjmp is 1 word

reset:
        ldi     r16, high(RAMEND)   ; put the stack at the top of SRAM
        out     sph, r16
        ldi     r16, low(RAMEND)
        out     spl, r16

main:
	ldi zh,high(pmv1*2) ; list in program memory
	ldi zl,low(pmv1*2)
	ldi xh,high(value1) ; list in sram (data memory)
	ldi xl,low(value1)
	ldi r16,0x08		; number of bytes in list
	rcall copybytes

fin:
	rjmp fin;

copybytes:
	tst r16
	breq cb_done

cb_loop:
	lpm r0, z+ ; r0 gets flash[Z] and increment Z (flash counter)
	st x+,r0   ; sram gets r0 and increment X (sram counter)
	dec r16    
	brne cb_loop

cb_done:
	ret

pmv1: .db 0x12, 0x34, 0x56, 0x78 
pmv2: .db 0x9A, 0xBC, 0xDE, 0xF0

; Data starts here (On this processor this is always 0x100)
	.dseg
	value1: .byte 4
	value2: .byte 4