BINS=meminit.bin
 
CC=riscv64-unknown-elf-gcc
CCFLAGS=-g -ffreestanding -O2 -march=rv32i -mabi=ilp32 -mcmodel=medany -static -fdata-sections -ffunction-sections
 
ELFS=meminit.elf
 
LDFLAGS=-Wl,--gc-sections -nostartfiles -Wl,-T,link.ld
 
OBJCPY=riscv64-unknown-elf-objcopy
OBJCPYFLAGS=-O binary
 
OBJDMP=riscv64-unknown-elf-objdump
OBJDMPFLAGS=-d
 
SRCS=crt0.s main.c
 
all: meminit.elf meminit.bin
 
clean:
    rm dump.txt $(ELFS) $(BINS)
 
disassemble:
    $(OBJDMP) $(OBJDMPFLAGS) $(ELFS) > dump.txt
    cat dump.txt
 
meminit.elf:
    $(CC) $(CCFLAGS) $(LDFLAGS) $(SRCS) -o $(ELFS)
 
meminit.bin:
    $(OBJCPY) $(OBJCPYFLAGS) $(ELFS) $(BINS)
    rm ~/AFTx06/$(BINS)
    cp $(BINS) ~/AFTx06/$(BINS)