#include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN
RVTEST_CODE_BEGIN

main:
    ori x1, x0, 1
    sll x1, x1, 13
    csrrs x2, mstatus, x1
    ori a0, a0, 0xff
    ori x4, x4, 0x25
    la x20, test1_op1
    flw f0, 0(x20)
    flw f1, 4(x20)
    fadd.s f2, f0, f1
    fmv.x.s x3, f2
    frflags x5
    sw x3, 8(x20)
    sw x5, 12(x20)

RVTEST_CODE_END
.data
    test1_op1: .float -1235.1
    test1_op2: .float 1.1 
    result: .word 0x00000000 
    flags: .word 0x00000000 

RVTEST_DATA_DUMP_END
