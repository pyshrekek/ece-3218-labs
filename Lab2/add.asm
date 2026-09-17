; add.asm
; Date: 9/17/2026

	.cseg
	jmp main
main:
	; copy 32 bit vals from flash into sram
	ldi zh, high(pmv1*2)
	ldi zl, low(pmv1*2)
	ldi xh, high(value1)
	ldi xl, low(value1)
	ldi r16, 8
	rcall copybytes

	ldi xh, high(value1) ; [x] <- addr(1st value MSB)
	ldi xl, low(value1);
	ldi r16, 8 ; countdown for two 4-byte numbers

pushloop:
	ld r0, x+ ; get values 1 and 2 from data memory
	push r0 ; push them to stack
	dec r16 ; MSB is first in
	brne pushloop ; continue till 8 bytes are done
	rcall sub32bit ; call the add function and return here when we are done

fin:
	rjmp fin

add32bit:
	; save return address
	pop r19 ; LSB of ra
	pop r18 ; MSB of ra
	; get numbers off stack and into local mem
	ldi xh, high(a32v1+8)
	ldi xl, low(a32v1+8)
	ldi r16,8 ; byte countdown

poploop:
	pop r0 ; pop byte off stack
	st -x, r0 ; store it in data memory
	dec r16 ; and continue until 8 bytes are done
	brne poploop

	; adding each byte
	; add LSB
	lds r20, a32v1+3
	lds r21, a32v1+7
	add r20, r21 ; doesnt read carry flag but writes it for the next op
	sts a32sum+3, r20

	; next bytes
	lds r20, a32v1+2
	lds r21, a32v1+6
	adc r20, r21
	sts a32sum+2, r20

	lds r20, a32v1+1
	lds r21, a32v1+5
	adc r20, r21
	sts a32sum+1, r20

	; add MSB
	lds r20, a32v1
	lds r21, a32v1+4
	adc r20, r21

	in r4, SREG ; preserve sreg
	sts a32sum, r20
	ldi xh, high(a32sum) ; [x] <- addr(sum MSB)
	ldi xl, low(a32sum)
	ldi r16, 4 ; number of bytes to push

pushloop2:
	; push the result onto the stack
	ld r0, x+ ; get sum byte from data mem
	push r0 ; push to stack
	dec r16 ; MSB is first in
	brne pushloop2 ; continue until 4 bytes are done
	out sreg, r4 ; restore status register
	push r18 ; MSB of return address
	push r19 ; LSB of return address
	ret

sub32bit:
	; save return address
	pop r19
	pop r18
	; takes two's complement of subtrahent
	; first flip the bits
	lds r20, value2
	com r20
	sts value2, r20

	lds r20, value2+1
	com r20
	sts value2+1, r20

	lds r20, value2+2
	com r20
	sts value2+2, r20

	lds r20, value2+3
	com r20
	sts value2+3, r20
	
	; addds 1 to complete the two's complement

	ldi r20, 1

	lds r21, value2+3
	add r21, r20
	sts value2+3, r21

	ldi r20, 0

	lds r21, value2+2
	adc r21, r20
	sts value2+2, r21

	lds r21, value2+1
	adc r21, r20
	sts value2+1, r21

	lds r21, value2
	adc r21, r20
	sts value2, r21

	ldi xh, high(value1)
	ldi xl, low(value1)
	ldi r16, 8

subpushloop:
	ld r0, x+
	push r0
	dec r16
	brne subpushloop
	push r18
	push r19
	rjmp add32bit

copybytes:
	lpm r0, z+ ; load byte form program memory, increment z
	st x+, r0 ; store byte into sram, increment x
	dec r16 ; decrement byte counter
	brne copybytes 
	ret

pmv1: ; hard coded data stored in program memory
	.db 0x0A, 0x0B, 0x0F, 0xEF
	.db 0x00, 0x00, 0x01, 0x11

	.dseg
value1: .byte 4
value2: .byte 4
a32v1: .byte 8
a32sum: .byte 4