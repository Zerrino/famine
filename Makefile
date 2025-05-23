NAME         = famine

ASM          = nasm
ASM64FLAGS   = -f elf64

LD           = ld
LDFLAGS      = -T link.ld

SRCDIR       = ./src/
OBJDIR       = ./obj/

SRC          = famine2.s
OBJ          = $(addprefix $(OBJDIR), $(SRC:.s=.o))

# ===== Targets =====

all: $(NAME)

$(NAME): $(OBJDIR) $(OBJ)
	$(LD) $(LDFLAGS) -o $(NAME) $(OBJ)

clean:
	rm -f $(NAME)

fclean: clean
	rm -rf $(OBJDIR)

re: fclean all

$(OBJDIR):
	@mkdir -p $(OBJDIR)

$(OBJDIR)%.o: $(SRCDIR)%.s
	$(ASM) $(ASM64FLAGS) $< -o $@

.PHONY: all clean fclean re