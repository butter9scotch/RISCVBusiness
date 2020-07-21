`ifndef TRANSACTION_SV
`define TRANSACTION_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class FPU_transaction extends uvm_sequence_item;
  logic f_LW; //load. Load from memory to register
  logic f_SW; //save. Save from rs2 to memory 
  logic f_wen; //write enable. Enable register file to written by FPU TODO: implementation of this signal

  logic [4:0] f_rs1; //register selection 1. Select operand 1 from a register
  logic [4:0] f_rs2; //register selection 2. Select operand 2 from a register
  logic [4:0] f_rd; //register destination. Select which register to be written

  logic [2:0] frm_in; //input rounding method.
  logic [7:0] f_funct_7; //operation selection of FPU
  
  logic [31:0] dload_ext; //TODO: confirm the identifier

  `uvm_object_utils_begin(FPU_transaction)
    `uvm_field_int(f_LW, UVM_DEFAULT)
    `uvm_field_int(f_SW, UVM_DEFAULT)
    `uvm_field_int(f_wen, UVM_DEFAULT)
    `uvm_field_int(f_rs1, UVM_DEFAULT)
    `uvm_field_int(f_rs2, UVM_DEFAULT)
    `uvm_field_int(f_rd, UVM_DEFAULT)
    `uvm_field_int(frm_in, UVM_DEFAULT)
    `uvm_field_int(f_funct_7, UVM_DEFAULT)
    `uvm_field_int(dload_ext, UVM_DEFAULT)

  `uvm_object_utils_end

  function new(string name = "FPU_transaction");
    super.new(name);
  endfunction: new

endclass //FPU_transaction

class FPU_response extends uvm_sequence_item;
  logic [4:0] f_flags; //a combination of NV, DZ, OF, UF, NX
  logic [31:0] FPU_all_out; //output when f_SW is asserted
  logic [2:0] f_frm_out; //frm outputed by register file TODO: confusing
  
  `uvm_object_utils_begin(FPU_transaction)
    `uvm_field_int(f_flags, UVM_DEFAULT)
    `uvm_field_int(FPU_all_out, UVM_DEFAULT)
    `uvm_field_int(f_frm_out, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "FPU_response");
    super.new(name);
  endfunction: new

endclass //FPU_response

`endif
