FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    nasm gcc make git strace netcat-openbsd vim openssh-client \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /root

CMD [ "bash" ]

