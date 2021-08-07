#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

.globl main
main:
    # Set up handler address
    #ecall (from decode stage) and illelegal memory address calculated from execute stage simultaneously

    li  TESTNUM, 1
    la t0, exception_handler
    csrw mtvec, t0
    auipc x2,0
    addi x2,  x2, 7
    lw x3, 0(x2)
    ecall
 back_to_main:
    j pass

exception_handler:
    csrr x7, mcause
    andi x7, x7, 0xFF # Mask lower bits -- top bit indicates interrupt vs. exception
    addi x1, x0, 0x4
    bne x7, x1, fail
    j back_to_main

pass:
 RVTEST_PASS
fail:
 RVTEST_FAIL

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
  TEST_DATA
RVTEST_DATA_END



