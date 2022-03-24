#include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN
RVTEST_CODE_BEGIN

main:
    ori x1, x0, 1
    sll x1, x1, 13
    csrrs x2, mstatus, x1
    la x5, tdat0
    la x7, tdat1 
    la x8, inf 
    la x6, main
    flw f0, 0(x5)
    flw f1, 0(x7)
    flw f3, 0(x6)
    #normal cases
    nop
    nop
    fadd.s f2, f0, f1
    nop
    nop
    fsw f2, 4(x8)
    fadd.s f4, f2, f3
    nop
    nop
    #infinity case
    fsw f4, 8(x8)
    flw f4, 0(x8)
    nop
    nop
    fadd.s f4, f4, f3
    nop
    nop
    fsw f4, 12(x8)
    #nan case
    fadd.s f4, f30, f0
    nop
    nop
    fsw f4, 16(x8)


RVTEST_CODE_END

.data
tdat0: .word 0x00002000
tdat1: .word 0x00000123
inf: .word 0x7f800000
tdat3: .word 0x00000000
tdat4: .word 0x00000000
tdat5: .word 0x00000000
tdat6: .word 0x00000000
RVTEST_DATA_DUMP_END
