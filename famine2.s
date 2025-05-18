BITS 64
default rel


section .text
	global _start

; %rdi %rsi %rdx %r10 %r8 %r9

_start:





.end:
	mov		rax, 60
	xor		rdi, rdi
	syscall
