#!/bin/bash
if [ $# -ne 1 ]; then
    echo not enough of arguments
    exit -1
fi
riscv64-unknown-elf-gcc -march=rv32g -mabi=ilp32f -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -T./verification/asm-env/link.ld -I./verification/asm-env/asm $1
elf2hex 8 65536 a.out 2147483648 > build/meminit.hex
