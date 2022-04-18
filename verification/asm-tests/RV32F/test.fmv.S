#include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN
RVTEST_CODE_BEGIN

main:
    ori x1, x0, 1
    sll x1, x1, 13
    csrrs x2, mstatus, x1
    la x5, data1
    ori x3, x3, 0xff
    fmv.s.x f1, x3
    fsw f1, 8(x5)
    flw f2, 0(x5)
    fmv.x.s x3, f2
    sw x3, 4(x5)

    
RVTEST_CODE_END
.data
data1: .word 0x12345678
res1: .word 0x00000000
res2: .word 0x00000000

RVTEST_DATA_DUMP_END
