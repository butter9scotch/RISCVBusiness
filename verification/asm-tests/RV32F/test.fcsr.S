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
    la x10, fcsr_contents
    fscsr x1, a0 #write 0xff csrrw x1, fcsr, a0
    frcsr x0 #csrs fcsr, x0
    sw x0, 0(x10)
    fsrm x5, x4 #write 0x25 csrrw x5, frm, tp
    frrm x3 #csrr x3, frm
    sw x3, 4(x10)
    fsflags x6, x3 #write frm into flags csrrw, x6, fflags, x3
    frflags x7 #csrr x7, fflags
    sw x7, 8(x10)
    fsrmi x5, 0x3 //write 3 to frm csrrwi x5, frm, 0x3
    sw x5, 12(x10)
    fsflagsi x6, 0x3 //write 3 to flags csrrwi x6, fflags, 3
    sw x6, 16(x10)
    frcsr x8
    sw x8, 20(x10)
    fadd.s f3, f0, f1
    frcsr x8
    fsw f3, 24(x10)
    sw x8, 28(x10)

RVTEST_CODE_END
.data
    fcsr_contents: .word 0x00000000
    frm_contents: .word 0x00000000
    flag_contents: .word 0x00000000
    frm_contents1: .word 0x00000000
    flag_contents2: .word 0x00000000
    final_fcsr_contents: .word 0x00000000
    res: .word 0x00000000
    final_fcsr_contents2: .word 0x00000000
    test1_op1: .word 0x40b4cccd //5.65
    test1_op2: .word 0x41865014 //16.7891

RVTEST_DATA_DUMP_END



