#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <elf.h>

#define XOR_KEY 0xdeadbeefdeadbeefULL

void xor_encrypt(uint8_t *data, size_t size, uint64_t key, size_t skip_offset, size_t skip_size) {
    uint8_t *k = (uint8_t *)&key;
    for (size_t i = 0; i < size; i++) {
        if (i >= skip_offset && i < skip_offset + skip_size)
            continue;
        data[i] ^= k[i % 8];
    }
}

int get_decryptor_range(const char *binary, size_t *offset_out, size_t *size_out) {
    char cmd[512];
    snprintf(cmd, sizeof(cmd),
        "nm '%s' 2>/dev/null | grep -E '(_encrypted_start|_start)' | awk '{print $1}'", binary);

    FILE *fp = popen(cmd, "r");
    if (!fp) return -1;

    char addr1[32] = {0}, addr2[32] = {0};
    if (!fgets(addr1, sizeof(addr1), fp)) {
        pclose(fp);
        return -1;
    }
    fgets(addr2, sizeof(addr2), fp); // may be NULL
    pclose(fp);

    size_t a = strtoull(addr1, NULL, 16);
    size_t b = addr2[0] ? strtoull(addr2, NULL, 16) : (a + 64);

    size_t start = (a < b) ? a : b;
    size_t end   = (a > b) ? a : b;

    *offset_out = start;
    *size_out = end - start;

    printf("🛡️  Decryption range: start = 0x%lx, end = 0x%lx, size = %lu bytes\n", start, end, end - start);

    return 0;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <binary>\n", argv[0]);
        return 1;
    }

    const char *bin = argv[1];
    FILE *f = fopen(bin, "rb+");
    if (!f) { perror("fopen"); return 1; }

    fseek(f, 0, SEEK_END);
    size_t size = ftell(f);
    rewind(f);

    uint8_t *buf = malloc(size);
    if (!buf) { perror("malloc"); fclose(f); return 1; }

    fread(buf, 1, size, f);

    Elf64_Ehdr *eh = (Elf64_Ehdr *)buf;
    if (memcmp(eh->e_ident, ELFMAG, SELFMAG) != 0 || eh->e_ident[EI_CLASS] != ELFCLASS64) {
        fprintf(stderr, "Invalid ELF64\n");
        free(buf); fclose(f); return 1;
    }

    Elf64_Shdr *sh = (Elf64_Shdr *)(buf + eh->e_shoff);
    const char *shstrtab = (char *)(buf + sh[eh->e_shstrndx].sh_offset);

    size_t skip_offset = 0, skip_size = 0;
    get_decryptor_range(bin, &skip_offset, &skip_size);

    int found = 0;
    for (int i = 0; i < eh->e_shnum; i++) {
        if (strcmp(&shstrtab[sh[i].sh_name], ".text") == 0) {
            size_t vaddr = sh[i].sh_addr;
            size_t offset = sh[i].sh_offset;
            size_t size = sh[i].sh_size;

            size_t rel_skip = (skip_offset >= vaddr && skip_offset < vaddr + size)
                              ? (skip_offset - vaddr) : 0;

            xor_encrypt(buf + offset, size, XOR_KEY, rel_skip, skip_size);
            found = 1;
            break;
        }
    }

    if (!found) {
        fprintf(stderr, "No .text section found\n");
        free(buf); fclose(f); return 1;
    }

    rewind(f);
    fwrite(buf, 1, size, f);
    fclose(f);
    free(buf);

    printf("✅ .text section encrypted, skipping %lu bytes at 0x%lx\n", skip_size, skip_offset);
    return 0;
}
