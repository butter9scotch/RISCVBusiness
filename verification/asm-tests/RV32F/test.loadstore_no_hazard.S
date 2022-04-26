#include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN
RVTEST_CODE_BEGIN

main:
    ori x1, x0, 1
    sll x1, x1, 13
    csrrs x2, mstatus, x1
    la x6, tdat0
    flw f0, 0(x6) 
    flw f1, 4(x6) 
    flw f2, 8(x6) 
    fadd.s f3, f1, f30
    fsw f0, 12(x6)
    fsw f1, 16(x6)
    fsw f2, 20(x6)
    fsw f3, 24(x6)

RVTEST_CODE_END

.data
tdat0: .word 0x00000001
tdat1: .word 0x00000002
tdat2: .word 0x00000015
tdat3: .word 0x00000000
tdat4: .word 0x00000000
tdat5: .word 0x00000000
tdat6: .word 0x00000000
RVTEST_DATA_DUMP_END
