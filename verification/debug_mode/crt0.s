
.section .init, "ax"            # This section holds initialization code that is allocatable and executable.
.global _start                  # Makes the `_start' symbol for entry into executable.
 
_start:                         # Defining `_start' subroutine.
    .cfi_startproc              # Signals the start of a function.
    .cfi_undefined ra           # Tells the assembler that register `ra' should not be restored.
    .option push                # Since we relax addressing sequences into shorter GP-relative sequences when
    .option norelax             # possible, the initial load of GP must not be relaxed.
    la gp, __global_pointer$
    .option pop
    la sp, __stack_top          # Loads the value of `__stack_top' into the `sp' register.
    add s0, sp, zero            # Adds the value of the `sp' register with zero (actually `x0') ans is placed in `s0'.
    jal zero, main              # Jump and `zero' to address of `main'.
    .cfi_endproc                # Signals the end of a function.
    .end                        # Marks the end of the assembly file.