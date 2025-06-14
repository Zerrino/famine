; Creates a 16-character hex signature:
; - Gets 8 random bytes
; - Gets current time
; - XORs both and rotates left
; - Converts result to 16 hex chars
; - Writes it at signature + 47
update_signature:
    PUSH_ALL
    
    mov rax, SYS_getrandom
    mov rdi, randbuf
    mov rsi, 8
    xor rdx, rdx
    syscall
    
    mov rax, SYS_time
    xor rdi, rdi
    syscall
    
    mov rdi, randbuf
    mov rbx, [rdi]
    xor rbx, rax
    rol rbx, 13
    mov [rdi], rbx

    mov rdi, signature
    add rdi, 47
    mov rcx, 8
    mov rsi, randbuf

.convert_loop:
    mov al, [rsi]
    call byte_to_hex
    mov [rdi], ax
    inc rsi
    add rdi, 2
    dec rcx
    jnz .convert_loop

    POP_ALL
    ret

byte_to_hex:
    push rcx
    mov ah, al
    shr al, 4
    and ah, 0x0F
    
    cmp al, 10
    jae .high_letter
    add al, '0'
    jmp .low
.high_letter:
    add al, 'a' - 10
    
.low:
    cmp ah, 10
    jae .low_letter
    add ah, '0'
    jmp .done
.low_letter:
    add ah, 'a' - 10
    
.done:
    pop rcx
    ret
