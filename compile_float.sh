#!/bin/bash
if [ $# -ne 1 ]; then
    echo not enough of arguments
    exit -1
fi
output_name=$(echo $1 | rev | cut -d '/' -f 1 | rev)
output_name=$(echo $output_name | cut -d '.' -f1,2)
full_output=$(echo $output_name".elf")
riscv64-unknown-elf-gcc -march=rv32if -mabi=ilp32f -static -mcmodel=medany -fvisibility=hidden -nostdlib -nostartfiles -T./verification/asm-env/link.ld -I./verification/asm-env/asm $1 -o $full_output
elf2hex 8 65536 $full_output 2147483648 > build/meminit.hex
