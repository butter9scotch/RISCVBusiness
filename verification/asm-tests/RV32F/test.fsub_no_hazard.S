#include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN
RVTEST_CODE_BEGIN

main:
    ori x1, x0, 1
    sll x1, x1, 13
    csrrs x2, mstatus, x1
    la x5, tdat0
    la x7, tdat1 
    la x6, main
    la x8, inf
    flw f0, 0(x5)
    flw f1, 0(x7)
    flw f3, 0(x6)
    nop
    nop
    fsub.s f2, f1, f0
    nop
    nop
    fsw f2, 4(x8)
    fsub.s f4, f2, f3
    nop
    nop
    fsw f4, 8(x8)
    #infinity case
    flw f4, 0(x8)
    nop
    nop
    fsub.s f4, f4, f2
    nop
    nop
    fsw f4, 12(x8)
    fsub.s f4, f3, f30
    nop
    nop
    fsw f4, 16(x8)



RVTEST_CODE_END

.data
tdat0: .word 0x0f002000
tdat1: .word 0x0e000123
inf: .word 0xff800000
tdat3: .word 0x00000000
tdat4: .word 0x00000000
tdat5: .word 0x00000000
tdat6: .word 0x00000000
RVTEST_DATA_DUMP_END
