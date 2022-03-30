#include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN
RVTEST_CODE_BEGIN

main:
    ori x1, x0, 1
    sll x1, x1, 13
    csrrs x2, mstatus, x1
    la x5, test1_op1
    la x9, res1
    flw f0, 0(x5)
    #normal cases
    nop
    nop
    fmul.s f2, f0, f1
    fmul.s f3, f1, f0
    nop
    nop
    fmul.s f4, f2, f3
    fsw f2, 0(x9)
    fsw f3, 4(x9)
    fsw f4, 8(x9)


RVTEST_CODE_END

.data
test1_op1: .word 0x40b4cccd //5.65
res1: .word 0x00000000
res2: .word 0x00000000
res3: .word 0x00000000

RVTEST_DATA_DUMP_END
