; Anti debug ---
_is_debugged:
	mov rdi, 0
	mov rax, SYS_ptrace
	xor rsi, rsi
	xor rdx, rdx
	xor r10, r10
	syscall
	ret


; Check forbidden process ---
_check_forbidden_process:
    push    r12
    push    r13
    push    r14
    push    r15
    
    mov     rax, SYS_open
    lea     rdi, [rel proc_prefix]
    xor     rsi, rsi
    xor     rdx, rdx
    syscall
    cmp     rax, 0
    jl      .ret_not_found
    mov     r12, rax               ; save /proc/ fd

.read_dir:
    mov     rax, SYS_getdents64
    mov     rdi, r12 ; use /proc/ fd
    lea     rsi, [rel buff]
    mov     rdx, 4096
    syscall
    cmp     rax, 0
    jle     .close_and_ret_not_found
    mov     r14, rax
    xor     r13, r13

.read_getdents_entry:
    cmp     r13, r14
    jge     .read_dir   

    lea     rdi, [rel buff]
    add     rdi, r13
    movzx   r10, word [rdi + 16] ; d_reclen
    mov     al, byte [rdi + 18] ; d_type
    lea     rsi, [rdi + 19]           
    add     r13, r10

    cmp     al, DT_DIR
    jne     .read_getdents_entry     

    push    rsi
    call    _is_numeric_string
    pop     rsi
    test    rax, rax
    jz      .read_getdents_entry 

    push    rsi                      
    mov     r15, rsi
    call    _parse_dir              
    pop     rsi
    test    rax, rax
    jnz     .close_and_ret_found
    jmp     .read_getdents_entry

.close_and_ret_found:
    mov     rax, SYS_close
    mov     rdi, r12 
    syscall
    mov     rax, 1
    jmp     .ret

.close_and_ret_not_found:
    mov     rax, SYS_close
    mov     rdi, r12
    syscall

.ret_not_found:
    xor     rax, rax

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret




; parse process dir ---
_parse_dir:
    push    rcx
    push    rdi
    push    rsi
    push    rdx
    push    r8
    
    lea     rdi, [rel path_buffer]
    xor     rax, rax
    mov     rcx, 64
    rep     stosq
    
    lea     rdi, [rel path_buffer]
    lea     rsi, [rel proc_prefix]
    mov     rcx, 6
    rep     movsb
    
    mov     rsi, r15
.copy_pid:
    lodsb
    test    al, al
    jz      .pid_done
    stosb
    jmp     .copy_pid
.pid_done:
    
    lea     rsi, [rel comm_path]
    mov     rcx, 6 
    rep     movsb
    
    mov     rax, SYS_open
    lea     rdi, [rel path_buffer]
    xor     rsi, rsi
    xor     rdx, rdx
    syscall
    
    test    rax, rax
    js      .ret_not_found
    mov     r8, rax

    mov     rax, SYS_read
    mov     rdi, r8
    lea     rsi, [rel comm_buff]
    mov     rdx, 15
    syscall
    
    push    rax
    mov     rax, SYS_close
    mov     rdi, r8
    syscall
    pop     rax
    
    test    rax, rax
    jle     .ret_not_found
    
    lea     rdi, [rel comm_buff]
    add     rdi, rax
    mov     byte [rdi], 0
    
    dec     rdi
    cmp     byte [rdi], 10
    jne     .no_newline
    mov     byte [rdi], 0
.no_newline:
    lea     rsi, [rel comm_buff]
    lea     rdi, [rel forbidden_process]
    call    ft_strcmp
    test    eax, eax
    jz      .found_forbidden
    
.ret_not_found:
    xor     rax, rax
    jmp     .ret
    
.found_forbidden:
    mov     rax, 1
    
.ret:
    pop     r8
    pop     rdx
    pop     rsi
    pop     rdi
    pop     rcx
    ret

; Utils ---
_is_numeric_string:
    push    rdi
    mov     rdi, rsi
.check_loop:
    mov     al, [rdi]
    test    al, al
    jz      .is_numeric
    cmp     al, '0'
    jl      .not_numeric
    cmp     al, '9'
    jg      .not_numeric
    inc     rdi
    jmp     .check_loop
.is_numeric:
    mov     rax, 1
    jmp     .done
.not_numeric:
    xor     rax, rax
.done:
    pop     rdi
    ret



ft_strcmp:
    push    rdi
    push    rsi
    push    rdx
    xor     eax, eax
    .loop:
        mov     al, [rdi]
        mov     dl, [rsi]
        cmp     al, dl
        jne     .diff
        test    al, al
        je      .done
        inc     rdi
        inc     rsi
        jmp     .loop
    .diff:
        sub     eax, edx
    .done:
        pop     rdx
        pop     rsi
        pop     rdi
        ret