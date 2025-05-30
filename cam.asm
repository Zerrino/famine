; Capture 10 trames depuis /dev/video0, mode mmap/streaming V4L2
; Pur syscall – NASM x86-64 – Linux

%define SYS_READ     0
%define SYS_WRITE    1
%define SYS_OPEN     2
%define SYS_CLOSE    3
%define SYS_IOCTL    16
%define SYS_MMAP     9
%define SYS_MUNMAP   11
%define SYS_EXIT     60

%define O_RDWR       02

; ioctl
%define VIDIOC_QUERYBUF     0xc0585609
%define VIDIOC_QBUF         0xc058560f
%define VIDIOC_DQBUF        0xc0585611


%define VIDIOC_REQBUFS      0xc0145608
%define VIDIOC_STREAMON     0x40045612
%define VIDIOC_STREAMOFF    0x40045613

%define V4L2_BUF_TYPE_VIDEO_CAPTURE 1
%define V4L2_MEMORY_MMAP    1

%define PROT_READ   1
%define PROT_WRITE  2
%define MAP_SHARED  1

%define NBUF 4               ; nombre de tampons
%define FRAMES 10            ; trames à capturer

; ---------- Données ------------------------------------------------
section .data
devname     db "/dev/video0",0
cap_type    dd V4L2_BUF_TYPE_VIDEO_CAPTURE   ; arg pour STREAMON/OFF

; ---------- BSS ----------------------------------------------------
section .bss
buf_addrs   resq NBUF        ; adresses mmap des tampons
buf_sizes   resq NBUF        ; leurs tailles
reqb        resb 16          ; struct v4l2_requestbuffers
v4buf       resb 88          ; struct v4l2_buffer (x86-64 = 88 o)

; ---------- Code ---------------------------------------------------
section .text
global _start
_start:
; --- open("/dev/video0", O_RDWR) -----------------------------------
    mov     rax, SYS_OPEN
    lea     rdi, [rel devname]
    mov     rsi, O_RDWR
    xor     rdx, rdx
    syscall
    mov     r12, rax          ; fd caméra

; --- VIDIOC_REQBUFS -----------------------------------------------
    mov     dword [reqb     ], NBUF
    mov     dword [reqb + 4 ], V4L2_BUF_TYPE_VIDEO_CAPTURE
    mov     dword [reqb + 8 ], V4L2_MEMORY_MMAP
    xor     eax, eax
    mov     [reqb + 12], eax  ; reserved = 0
    mov     rax, SYS_IOCTL
    mov     rdi, r12
    mov     rsi, VIDIOC_REQBUFS
    lea     rdx, [rel reqb]
    syscall

; --- Boucle QUERYBUF + mmap + QBUF --------------------------------
%assign i 0
%rep NBUF
    ; struct v4l2_buffer -> index/type/memory
    mov     dword [v4buf     ], i
    mov     dword [v4buf + 4 ], V4L2_BUF_TYPE_VIDEO_CAPTURE
    mov     dword [v4buf + 60], V4L2_MEMORY_MMAP

    ; VIDIOC_QUERYBUF
    mov     rax, SYS_IOCTL
    mov     rdi, r12
    mov     rsi, VIDIOC_QUERYBUF
    lea     rdx, [rel v4buf]
    syscall

    ; mmap(fd, length, …, offset)
    mov     rax, SYS_MMAP
    xor     rdi, rdi                          ; addr = NULL
    mov     edx, [v4buf + 72]                 ; length (dword) → edx
    mov     esi, edx                          ; rsi = length
    mov     edx, PROT_READ | PROT_WRITE       ; rdx
    mov     r10, MAP_SHARED
    mov     r8,  r12                          ; fd
    mov     r9,  [v4buf + 64]                 ; offset (qword)
    syscall
    mov     [buf_addrs + i*8], rax            ; save address
    mov     eax, [v4buf + 72]
    mov     [buf_sizes + i*8], rax            ; save size (dword → qword)

    ; rempile la même struct pour QBUF (index/type/memory déjà OK)
    mov     rax, SYS_IOCTL
    mov     rdi, r12
    mov     rsi, VIDIOC_QBUF
    lea     rdx, [rel v4buf]
    syscall
%assign i i+1
%endrep

; --- VIDIOC_STREAMON ----------------------------------------------
    mov     rax, SYS_IOCTL
    mov     rdi, r12
    mov     rsi, VIDIOC_STREAMON
    lea     rdx, [rel cap_type]
    syscall

    mov     rcx, FRAMES
.capture_loop:
    push rcx
    ; DQBUF ---------------------------------------------------------
    mov     rax, SYS_IOCTL
    mov     rdi, r12
    mov     rsi, VIDIOC_DQBUF
    lea     rdx, [rel v4buf]
    syscall

    ; sortir la trame sur stdout
    mov     ebx, [v4buf]                      ; index (dword)
    mov     edx, [v4buf + 8]                  ; bytesused
    mov     rsi, [buf_addrs + rbx*8]          ; addr
    mov     rdi, 1                            ; stdout
    mov     rax, SYS_WRITE
    syscall

    ; remettre le tampon dans la file (QBUF) ------------------------
    mov     rax, SYS_IOCTL
    mov     rdi, r12
    mov     rsi, VIDIOC_QBUF
    lea     rdx, [rel v4buf]
    syscall
    pop rcx
    loop    .capture_loop

; --- STREAMOFF -----------------------------------------------------
    mov     rax, SYS_IOCTL
    mov     rdi, r12
    mov     rsi, VIDIOC_STREAMOFF
    lea     rdx, [rel cap_type]
    syscall

; --- close & exit --------------------------------------------------
    mov     rax, SYS_CLOSE
    mov     rdi, r12
    syscall

    mov     rax, SYS_EXIT
    xor     rdi, rdi
    syscall

