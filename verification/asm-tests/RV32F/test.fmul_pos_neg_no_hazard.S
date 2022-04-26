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
    la x10,test3_op1
    la x11, test3_op2
    flw f0, 0(x5)
    flw f1, 0(x6)
    flw f2, 0(x7)
    flw f3, 0(x8)
    flw f4, 0(x10)
    flw f5, 0(x11)
    #normal cases
    fmul.s f7, f0, f1
    fmul.s f8, f2, f3
    fmul.s f9, f4, f5
    fsw f7, 0(x9)
    fsw f8, 4(x9)
    fsw f9, 8(x9)


RVTEST_CODE_END

.data
test1_op1: .word 0x40b4cccd //5.65
test1_op2: .word 0xc1865014 //-16.7891
test2_op1: .word 0xcb3c4efb //-12340987.13
test2_op2: .word 0x5256aa7a //230495780987.1
test3_op1: .word 0xcb3c4efb //-12340987.13
test3_op2: .word 0x4b3c4efb //12340987.13
res1: .word 0x00000000
res2: .word 0x00000000
res3: .word 0x00000000

RVTEST_DATA_DUMP_END
