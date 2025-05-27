NAME         = famine
ENCRYPTOR    = encrypt

ASM          = nasm
ASM64FLAGS   = -f elf64

CC           = gcc
CFLAGS       = #-Wall -Wextra 

LD           = ld
LDFLAGS      = -T link.ld

SRCDIR       = ./src/
OBJDIR       = ./obj/

ASM_SRC      = famine2.s
ASM_OBJ      = $(addprefix $(OBJDIR), $(ASM_SRC:.s=.o))

C_SRC        = encrypt.c
C_OBJ        = $(addprefix $(OBJDIR), $(C_SRC:.c=.o))

# ===== Targets =====

all: $(NAME) $(ENCRYPTOR)

$(NAME): $(ENCRYPTOR) $(OBJDIR) $(ASM_OBJ)
	$(LD) $(LDFLAGS) -o $(NAME) $(ASM_OBJ)
	./$(ENCRYPTOR) $(NAME)


$(ENCRYPTOR): $(C_OBJ)
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(NAME) $(ENCRYPTOR)

fclean: clean
	rm -rf $(OBJDIR)

re: fclean all

$(OBJDIR):
	@mkdir -p $(OBJDIR)

# Compile NASM files
$(OBJDIR)%.o: $(SRCDIR)%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Compile C files
$(OBJDIR)%.o: $(SRCDIR)%.s | $(OBJDIR)
	$(ASM) $(ASM64FLAGS) $< -o $@

