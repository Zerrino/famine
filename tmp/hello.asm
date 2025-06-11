%include "src/famine.inc"

BITS 64
default rel

section .text
	global _start

; %rdi %rsi %rdx %r10 %r8 %r9

find_eq:
	PUSH_ALLr
	xor		rax, rax
	mov		rsi, r15
	mov		rdi, rdx
	mov		r9, rcx
	dec		r9
	mov		rcx, r8

	cmpb:
		mov		r14b, byte [rsi]
		mov		r15b, byte [rdi]
		cmp		r14b, r15b
		jne		.quit_loop

		.skip:
		inc		rsi	;	Le  code
		inc		rdi	;	Les nombres
	loop	cmpb

	inc		rax
	.quit_loop:
	POP_ALLr
	ret



replace:
	PUSH_ALL
	mov		r15, rax
	mov		r14, rdx
	mov		rax, rcx
	mov		rcx, r9
	finding_equal:	; LOOP SUR LE NOMBRE DE R9 NUMBERS DONC MANIERES DE MODIFIER
		call	find_eq
		test	rax, rax
		jnz		.equl
		add		rdx, r8
	loop	finding_equal
	jmp		.ret
	.equl:

	mov		rcx, r8


	PUSH_ALLr
	xor		rax, rax
	mov		rdi, urandom_path
	xor		rsi, rsi
	mov		rax, SYS_open
	syscall
	mov		r12, rax
	mov		rdi, r12
	lea		rsi, [rel randbuf]
	mov		rdx, 8
	mov		rax, SYS_read
	syscall
	mov		rdi, r12
	mov		rax, SYS_close
	syscall
	mov		rax, [rel randbuf]
	xor		rdx, rdx
	mov		rcx, r9
	div		rcx
	mov		rax, rdx
	POP_ALLr

	; r15 le code
	; r14  les instructions

	imul	r8, rax
	add		r14, r8
	mov		rsi, r14
	mov		rdi, r15

	rep		movsb

	.ret:
	POP_ALL
	ret


; RAX = START, RDI = END, RDX = FUNC ADDR, R8 = LEN, R9 = NUMBER
polymorph:
	PUSH_ALL
	mov		rcx, rdi
	sub		rcx, rax
	sub		rcx, r8

	loop_start:

	call	replace

	inc		rax
	loop	loop_start
	POP_ALL
	ret


_start:
	lea		rax, [rel _start]
	lea		rdi, [rel _end]
	lea		rdx, [rel templates]
	mov		r8, 7
	mov		r9, 4
	call	polymorph


	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
	mov		rax, 60
	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
value:
	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
	syscall
_end:
templates:
	db 0x48, 0x31, 0xff, 0x90, 0x90, 0x90, 0x90  ; xor, rdi, rdi
	db 0x48, 0xc7, 0xc7, 0x00, 0x00, 0x00, 0x00  ; mov rdi , 0
	db 0x48, 0x29, 0xff, 0x90, 0x90, 0x90, 0x90	 ; sub rdi, rdi
	db 0x48, 0x83, 0xe7, 0x00, 0x90, 0x90, 0x90	 ; and rdi, 0
	urandom_path : db '/dev/urandom', 0
	randbuf: dq 0
