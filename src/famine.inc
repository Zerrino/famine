%define SYS_read		0
%define SYS_write		1
%define SYS_open		2
%define SYS_close		3
%define SYS_pread64		17
%define SYS_pwrite64	18
%define SYS_getdents64	217
%define SYS_exit		60
%define O_RDONLY		0
%define SYS_openat		257
%define AT_FDCWD  -100

%define FAMINE_SIZE end_addr - _start

%macro PUSH_ALL 0
    push	rax
    push	rbx
    push	rcx
    push	rdx
    push	rsi
    push	rdi
    push	rbp
    push	r8
    push	r9
    push	r10
    push	r11
    push	r12
    push	r13
    push	r14
    push	r15
%endmacro

%macro POP_ALL 0
    pop		r15
    pop		r14
    pop		r13
    pop		r12
    pop		r11
    pop		r10
    pop		r9
    pop		r8
    pop		rbp
    pop		rdi
    pop		rsi
    pop		rdx
    pop		rcx
    pop		rbx
    pop		rax
%endmacro