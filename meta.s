%include "src/famine.inc"

BITS 64
org 0x0                     ; PIE = pas d’adresse fixe

file:
; ELF64 Header (64 bytes)
db 0x7F, "ELF"              ; Magic
db 2                        ; EI_CLASS = ELF64
db 1                        ; EI_DATA = little endian
db 1                        ; EI_VERSION
db 0                        ; EI_OSABI
db 0                        ; EI_ABIVERSION
times 7 db 0                ; padding

dw 3                        ; e_type = ET_DYN (PIE)
dw 0x3E                     ; e_machine = x86_64
dd 1                        ; e_version
dq _start                   ; e_entry (relative to base)
dq 64                       ; e_phoff
dq 0                        ; e_shoff
dd 0                        ; e_flags
dw 64                       ; e_ehsize
dw 56                       ; e_phentsize
dw 1                        ; e_phnum
dw 0                        ; e_shentsize
dw 0                        ; e_shnum
dw 0                        ; e_shstrndx

; Program Header
dd 1                        ; p_type = PT_LOAD
dd 7                        ; p_flags = R | X
dq 0                        ; p_offset
dq 0                        ; p_vaddr
dq 0                        ; p_paddr
dq end_addr - _start:                ; p_filesz
dq end_addr -_start:                ; p_memsz
dq 0x1000                   ; p_align



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

	jmp		v
	db		10
	v:

	lea		rsi, [rel v - 1]
	mov		rdx, 1
	syscall

    add     rsp, 64             ; restaurer la pile
    POP_ALL
    ret


; %rdi %rsi %rdx %r10 %r8 %r9

_start:

	mov	rax, 2
	lea 	rdi, [rel nam]
	mov	rsi, 102
	mov	rdx, 111111111b
	syscall
	cmp	rax, 0
	jl	.continue
	mov	r12, rax

	push	r12

.continue:
	jmp	write
	; 48 8d 05 00 00 00 00 LEA RAX, 0

	; BLOC 0
	msgfind: db 'Found!', 10, 0

	; RDI START, RSI END

	patchjmp:
	mov		qword [rel patchjmp.nbr], 4
	mov		dword [rel patchjmp.ptc], 0
	mov		qword [rel patchjmp.inc], 0
	jmp	.start
	.nbr:	dq 4
	.adr:	times 4 dq 0
	.ptc:	dq 0x421900000000
	.blc:	dq 1942
	.inc:	dq 0
	.start:
	; STEP 1 FINDING ADDR

	mov	r14, rdi
	mov	r15, rsi


	jmp	.cont
	.restart:
	pop	rdi
	pop	rsi
	pop	rcx
	mov	rdi, r14
	.cont:
	mov	rcx, r15
	sub	rcx, r14

	.loop_find_addr:
	push	rcx
	push	rsi
	push	rdi

	mov	rcx, 16
	lea	rsi, [rel .blc]

	repe	cmpsb
	jnz	.noeq



	mov		rax, [rel .inc]
	imul	rax, 8
	lea		rsi, [rel .adr]
	add		rsi, rax


	mov		[rsi],  rdi
	inc		qword [rel .inc]
	mov		rax, [rel .inc]
	cmp		rax, [rel .nbr]
	jne		.restart
	.noeq:
	pop		rdi
	pop		rsi
	pop		rcx
	inc		rdi
	loop	.loop_find_addr

	; Ici on va s'occuper de patcher les addresses
	mov		rdi, r14
	mov		rsi, r15

	jmp	.cont0
	.restart0:
	pop	rdi
	pop	rsi
	pop	rcx
	mov	rdi, r14
	.cont0:
	mov	rcx, r15
	sub	rcx, r14

	.loop_find_addr0:
	push	rcx
	push	rsi
	push	rdi

	mov	rcx, 8
	lea	rsi, [rel .ptc]

	repe	cmpsb
	jnz	.noeq0

	xor		rax,rax
	mov		eax, [rel .ptc]

	imul	rax, 8
	lea		rsi, [rel .adr]
	add		rsi, rax



	mov		rsi, [rsi] ;se trouve les bonnes values
	sub		rdi, 8
	mov		[rdi], rsi

	inc		qword [rel .ptc]
	jne		.restart0
	.noeq0:
	pop		rdi
	pop		rsi
	pop		rcx
	inc		rdi
	loop	.loop_find_addr0

	ret

	; RDI -> START_SHUFFLE, RSI -> END_SHUFFLE
shuffle:
	xor		r13, r13
	mov		r14, rdi
	mov		r15, rsi

	mov		rcx, r15
	sub		rcx, r14

	push	rcx
	mov		rax, SYS_mmap
	xor		rdi, rdi
	mov		rsi, rcx
	mov		rdx, PROT_READ | PROT_WRITE
	mov		r10, MAP_PRIVATE | MAP_ANONYMOUS
	mov		r8, -1
	xor		r9, r9
	syscall
	pop		rcx
	mov		r12, rax
	cmp		rax, 0
	jb		.munmap
	push	rcx

	;mov		rsi, r14
	;mov		rdi, r12
	;rep		movsb
	PUSH_ALL
	mov		rax, SYS_open
	lea		rdi,  [rel .urnd_path]
	xor		rsi,  rsi
	xor		rdx,  rdx
	syscall
	mov		r12, rax
	js		.done_shuffle
	mov		rax, SYS_read
	mov		rdi, r12
	lea		rsi, [rel .randbuf]
	mov		rdx, 3
	syscall
	mov		rax, SYS_close
	mov		rdi, r12
	syscall
	mov		rcx, 2
	.fy_loop:
		cmp		rcx, 0
		jl		.done_shuffle
		lea		rax, [rel .randbuf]
		add		rax, rcx
		movzx	eax, byte [rax]
		xor		rdx, rdx
		mov		rbx, rcx
		inc		rbx
		div		rbx
		mov		rbx, rdx
		lea		rsi, [rel .str]
		mov		al, [rsi + rcx]
		mov		dl, [rsi + rbx]
		mov		[rsi + rcx], dl
		mov		[rsi + rbx], al
		dec		rcx
		jmp		.fy_loop
	.done_shuffle:

	POP_ALL
	mov		rax, SYS_write
	mov		rdi, 1
	lea		rsi, [rel .str]
	mov		rdx, 4
	syscall

	jmp		.af
	.ptc:	dq 0x696900000001
	.blc:	dq 1942
	.inc:	dq 0
	.str:	db "012", 10
	.urnd_path: db "/dev/urandom", 0
	.randbuf:	times 3 db 0
	.af:

	mov		rcx, 3

	.big_loop:
	cmp		rcx, 0
	jle		.noeq

	mov		rax, rcx
	dec		rax
	push	rcx
	mov		rcx, r15
	sub		rcx, r14
	mov		rdi, r14

	lea		rsi, [rel .str]
	add		rsi, rax

	mov		al, [rsi]
	sub		al, '0'
	mov		 [rel .inc], al
	inc		al
	mov		 [rel .ptc], al
	.loop_first_addr:
	push	rcx
	mov		rcx, 16
	lea		rsi, [rel .blc]
	repe	cmpsb
	pop		rcx
	jz		.continuen
	loop	.loop_first_addr
	jmp		.noeq


	.continuen:
	mov		r9, rdi

	.loop_second_addr:
	push	rcx
	mov		rcx, 8
	lea		rsi, [rel .ptc]
	repe	cmpsb
	pop		rcx
	jz		.continuex
	loop	.loop_second_addr
	jmp		.noeq

	.continuex:
	mov		r10, rdi

	; Donc ici r9 = start
	sub		r9, 16
	; et r10 = end




	mov		rcx, r10
	sub		rcx, r9

	mov		rax, r12
	add		rax, r13
	add		r13, rcx

	mov		rsi, r9
	mov		rdi, rax
	rep		movsb

	pop		rcx
	dec		rcx
	jmp		.big_loop


	.noeq:
	mov		rcx, r15
	sub		rcx, r14
	mov		rsi, r12
	mov		rdi, r14
	rep		movsb

	pop		rcx
	.munmap:
	mov		rax, SYS_munmap
	mov		rdi, r12
	mov		rsi, rcx
	syscall
ret


write:


	lea	rdi, [rel start_shuffle]
	lea	rsi, [rel end_shuffle]
	call	shuffle


	pop		r12
	mov	al, [rel ctn]
	inc	al
	mov	[rel ctn], al

	mov	rax, 1
	mov	rdi, r12
	lea	rsi, [rel file]
	lea	rdx, [rel end_addr]
	lea	rcx, [rel file]
	sub	rdx, rcx
	syscall

	mov	rax, 3
	mov	rdi, r12
	syscall



	lea	rdi, [rel code]
	lea	rsi, [rel end_code]

	call	patchjmp
	code:


	jmp	[rel .addr0]
	.addr0:	dq 0x421900000000
	start_shuffle:
	; BLOC 0
	dq	1942, 0
	bloc0:
	mov	rax, 1
	mov	rdi, 1
	jmp	msg0
	db  'SALUT'
	db 	'0', 10, 0
	msg0:
	lea	rsi, [rel msg0 - 3]
	mov	rdx, 2
	syscall
	jmp	[rel .addr1]
	.addr1: dq 0x421900000001
	dq 0x696900000001

	; BLOC 1
	dq	1942, 1
	bloc1:
	mov	rax, 1
	mov	rdi, 1
	jmp	msg1
	db  'BONJOUR'
	db 	'1', 10, 0
	msg1:
	lea	rsi, [rel msg1 - 3]
	mov	rdx, 2
	syscall
	jmp	[rel .addr2]
	.addr2: dq 0x421900000002
	dq 0x696900000002
	; BLOC 2
	dq	1942, 2
	bloc2:
	mov	rax, 1
	mov	rdi, 1
	jmp	msg2
	db  'AHAHAH'
	db 	'2', 10, 0
	msg2:
	lea	rsi, [rel msg2 - 3]
	mov	rdx, 2
	syscall
	jmp	[rel .addr3]
	.addr3: dq 0x421900000003
	dq 0x696900000003
	end_shuffle:
	dq	1942, 3
	end_code:
	mov	rax, 60
	xor	rdi, rdi
	syscall

	nam: db 'hello'
	ctn: db '0', 0
end_addr:
