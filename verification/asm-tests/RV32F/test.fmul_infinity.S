
#include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN
RVTEST_CODE_BEGIN

main:
    ori x1, x0, 1
    sll x1, x1, 13
    csrrs x2, mstatus, x1
    la x5, test1_op1
    la x6, test1_op2
    la x7, test2_op1
    la x8, test2_op2
    la x9, res1
    flw f2, 0(x7)
    flw f3, 0(x8)
    #normal cases
    flw f0, 0(x5)
    flw f1, 0(x6)
    fmul.s f4, f0, f1
    fmul.s f5, f2, f3
    fmul.s f6, f0, f2
    fadd.s f7, f3, f1
    fmul.s f8, f7, f0
    fsw f8, 12(x9)
    fsw f4, 0(x9)
    fsw f5, 4(x9)
    fsw f6, 8(x9)


RVTEST_CODE_END

.data
test1_op1: .word 0x7f800000 //infinity
test1_op2: .word 0x40d00000 //6.5
test2_op1: .word 0xff800000 //-infinity
test2_op2: .word 0xc0d00000 //-6.5
res1: .word 0x00000000
res2: .word 0x00000000
res3: .word 0x00000000
res4: .word 0x00000000

RVTEST_DATA_DUMP_END
