; - Computes a checksum of the file
; - Gets the current time (seconds.microseconds)
; - Converts both to a readable string
; - Writes the result at offset +47 in the `signature` buffer
; <checksum>:<time>

update_signature:
    PUSH_ALL

    mov rsi, r14
    mov rdi, [rel file_size]
    xor rbx, rbx

.checksum_loop:
    movzx rax, byte [rsi]
    add rbx, rax
    rol rbx, 1
    inc rsi
    dec rdi
    jnz .checksum_loop

    mov [rel temp_buf], rbx

    mov rax, 96
    lea rdi, [rel timeval]
    xor rsi, rsi
    syscall

    lea rdi, [rel signature]
    add rdi, 47
    mov rcx, 8
    lea rsi, [rel temp_buf]

.convert_checksum:
    mov al, byte [rsi]
    call byte_to_hex
    mov [rdi], ax
    inc rsi
    add rdi, 2
    dec rcx
    jnz .convert_checksum

    mov byte [rdi], ':'
    inc rdi

    mov rsi, [rel timeval]
    call number_to_string

    mov byte [rdi], '.'
    inc rdi

    mov rsi, [rel timeval + 8]
    call number_to_string

    POP_ALL
    ret

number_to_string:
    push rbx
    push rcx
    push rdx

    mov rax, rsi
    mov rbx, 10
    xor rcx, rcx

.divide_loop:
    xor rdx, rdx
    div rbx
    push rdx
    inc rcx
    test rax, rax
    jnz .divide_loop

.store_loop:
    pop rax
    add al, '0'
    mov [rdi], al
    inc rdi
    dec rcx
    jnz .store_loop

    mov byte [rdi], 0

    pop rdx
    pop rcx
    pop rbx
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
