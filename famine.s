BITS 64
default rel


section .text
	global _start


	; %rdi %rsi %rdx %r10 %r8 %r9

_start:
	jmp entry_point
	num0 dq 0
	num1 dq 0
	num2 dw 0 dw, 0
	stnl db 10
	buf0 dq 0
	buf1 dq 0
	file db	'./test', 0, 10
	msg1 db	'file is elf', 10, 0
	msg2 db	'file is 64', 10, 0
	elfh db 0x7F, 'ELF'
entry_point:

	lea		rdi, [rel _start]
	lea		rax, [rel .true_end]
	sub		rax, rdi
	mov		rbx, 10
	lea		rdi, [rel num0 + 20]
	xor		rcx, rcx

.convert_loop:
	xor		rdx, rdx
	div		rbx
	dec		rdi
	add		dl, '0'
	mov		[rdi], dl
	inc		rcx
	test	rax, rax
	jnz		.convert_loop
	mov		rax, 1
	lea		rsi, [rdi]
	mov		rdi, 1
	mov		rdx, rcx
	inc		rdx
	inc		rdx
	syscall

	mov		rax, 1
	mov		rdi, 1
	lea		rsi, [rel file]
	mov		rdx, 8
	syscall

	mov		rax, 2
	lea		rdi, [rel file]
	mov		rsi, 2
	xor		rdx, rdx
	syscall

	mov		r8, rax

	xor		rax, rax
	mov		rdi, r8
	lea		rsi, [rel buf0]
	mov		rdx, 16
	syscall


	mov		rcx, 4
	lea		rsi, [rel buf0]
	lea		rdi, [rel elfh]
	repe	cmpsb
	test	rcx, rcx
	jnz		.end

	mov		rax, 1
	mov		rdi, 1
	lea		rsi, [rel msg1]
	mov		rdx, 12
	syscall

	cmp		byte [rel buf0 + 4], 2
	jne		.end

	mov		rax, 1
	mov		rdi, 1
	lea		rsi, [rel msg2]
	mov		rdx, 11
	syscall


.end:
	mov		rax, 60
	xor		rdi, rdi
	syscall
.true_end:
