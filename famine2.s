BITS 64
default rel

%define SYS_write		1
%define SYS_open		2
%define SYS_getdents64	217
%define SYS_exit		60
%define O_RDONLY		0

section .text
	global _start

; %rdi %rsi %rdx %r10 %r8 %r9


_start:
	jmp		end_

	buff	times 4096 db 0
	newl	times 0001 db 0xa
	text	db 'blabla', 0 ,0 , 0
	path	db '/test_dir/coucou/test/', 0
	padd	times 0512 db 0

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

	remove_val:	; lea rsi
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
			cmp		rdx, 2
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
				mov		[rsi - 1], byte '/'
				mov		[rsi], byte 0
				sub		rsi, rax
				sub		rsi, rdx
		pop		rdx
		pop		rdi
		pop		rsi
		pop		rcx
		pop		rax
	ret

	famine:
		lea		rsi, [rel path]


	ret
end_:

	call	famine


	mov		rax, SYS_exit
	xor		rdi, rdi
	syscall
end_addr:
