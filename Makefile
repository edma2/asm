mmcp: mmcp.o
	ld -o mmcp mmcp.o
mmcp.o: mmcp.asm
	nasm -g -f elf -o mmcp.o mmcp.asm
