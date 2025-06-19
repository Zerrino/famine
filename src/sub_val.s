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
