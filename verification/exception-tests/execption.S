#include "riscv_test.h"
#include "test_macros.h"

RVTEST_RV32U
RVTEST_CODE_BEGIN

.globl main
main:
    # Set up handler address
    la t0, illegal_jump_addr
    csrw mtvec, t0

test1:
    li  TESTNUM, 1
    auipc x2,0
    addi x2,  x2, 7
    jalr x1, x2, 0
test2:
    li  TESTNUM, 2
    la t0, illegal_lw_addr
    csrw mtvec, t0
    lw x3, 0(x2)
test3:
    li  TESTNUM, 3
    la t0, illegal_sw_addr
    csrw mtvec, t0
    sw x0, 0(x2)
 test4: 
    li  TESTNUM, 4
    la t0, ecall_insn
    csrw mtvec, t0
    ecall
 test5:
    li  TESTNUM, 5
    la t0, ebreak_insn
    csrw mtvec, t0
    ebreak
  test6:
    j pass

illegal_jump_addr:
    csrr x7, mcause
    andi x7, x7, 0xFF # Mask lower bits -- top bit indicates interrupt vs. exception
    bne x7, x0, fail
    j test2

illegal_lw_addr:
    csrr x7, mcause
    andi x7, x7, 0xFF # Mask lower bits -- top bit indicates interrupt vs. exception
    addi x1, x0, 0x4
    bne x7, x1, fail
    j test3

illegal_sw_addr:
    csrr x7, mcause
    andi x7, x7, 0xFF # Mask lower bits -- top bit indicates interrupt vs. exception
    addi x1, x0, 0x6
    bne x7, x1, fail
    j test4

 ecall_insn:
    csrr x7, mcause
    andi x7, x7, 0xFF # Mask lower bits -- top bit indicates interrupt vs. exception
    addi x1, x0, 0xB
    bne x7, x1, fail
    j test5

 ebreak_insn:
    csrr x7, mcause
    andi x7, x7, 0xFF # Mask lower bits -- top bit indicates interrupt vs. exception
    addi x1, x0, 0x3
    bne x7, x1, fail
    j test6

pass:
 RVTEST_PASS
fail:
 RVTEST_FAIL

RVTEST_CODE_END

.data
RVTEST_DATA_BEGIN
  TEST_DATA
RVTEST_DATA_END
  
