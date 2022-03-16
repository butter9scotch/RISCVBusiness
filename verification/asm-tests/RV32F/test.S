#include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN
RVTEST_CODE_BEGIN

main:
    ori x1, x0, 1
    sll x1, x1, 13
    la x5, tdat0
    csrrs x2, mstatus, x1
    la x6, main
    flw f20, 0(x6)
    nop
    nop
    fadd.s f30, f20, f0
    nop
    nop
    fadd.s f21, f30, f1
    nop
    nop
    fadd.s f22, f21, f30
    fsw f22, 0(x5)

RVTEST_CODE_END

.data
tdat0: .word 0x00000001
RVTEST_DATA_DUMP_END
