build:
	nasm -f elf64 -o main.o main.asm
	ld main.o -o main

