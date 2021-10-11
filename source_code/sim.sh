#! /bin/bash

export HEADER_FILES="-incdir ./include"
export STANDARD_CORE_FILES="standard_core/rv32v_reg_file.sv"
export TB="tb/tb_rv32v_reg_file.sv"
# export PKG_FILES="-incdir ./packages"
# export PKG_FILES="packages/rv32v_types_pkg.sv"
# export PKG_FILES="packages/rv32v_types_pkg.sv"
export PKG_FILES="packages/rv32v_types_pkg.sv packages/rv32i_types_pkg.sv packages/alu_types_pkg.sv packages/machine_mode_types_1_11_pkg.sv  packages/machine_mode_types_pkg.sv packages/pipe5_types_pkg.sv"



# irun -access +rwc -timescale 1ns/1ns -shm -gui $PKG_FILES $HEADER_FILES $STANDARD_CORE_FILES $TB 
irun -access +rwc -timescale 1ns/1ns -shm -gui $PKG_FILES $HEADER_FILES $STANDARD_CORE_FILES $TB 