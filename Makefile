mmcp: mmcp.o
	ld -o mmcp mmcp.o
mmcp.o: mmcp.asm
	nasm -f elf -o mmcp.o mmcp.asm
