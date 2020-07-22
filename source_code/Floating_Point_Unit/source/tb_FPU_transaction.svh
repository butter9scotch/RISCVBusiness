`ifndef TRANSACTION_SV
`define TRANSACTION_SV

import uvm_pkg::*;
`include "uvm_macros.svh"

class FPU_transaction extends uvm_sequence_item;
  rand logic f_LW; //load. Load from memory to register
  rand logic f_SW; //save. Save from rs2 to memory 

  rand logic [4:0] f_rs1; //register selection 1. Select operand 1 from a register
  rand logic [4:0] f_rs2; //register selection 2. Select operand 2 from a register
  rand logic [4:0] f_rd; //register destination. Select which register to be written

  rand logic [2:0] f_frm_in; //input rounding method.
  rand logic [6:0] f_funct_7; //operation selection of FPU
  
  rand logic [31:0] dload_ext; //TODO: confirm the identifier

  `uvm_object_utils_begin(FPU_transaction)
    `uvm_field_int(f_LW, UVM_DEFAULT)
    `uvm_field_int(f_SW, UVM_DEFAULT)
    `uvm_field_int(f_rs1, UVM_DEFAULT)
    `uvm_field_int(f_rs2, UVM_DEFAULT)
    `uvm_field_int(f_rd, UVM_DEFAULT)
    `uvm_field_int(f_frm_in, UVM_DEFAULT)
    `uvm_field_int(f_funct_7, UVM_DEFAULT)
    `uvm_field_int(dload_ext, UVM_DEFAULT)
  `uvm_object_utils_end

  localparam ADD = 7'b0000000;
  localparam MUL = 7'b0001000;
  localparam SUB = 7'b0000100; 

  localparam RNE = 3'b000;
  localparam RZE = 3'b001;
  localparam RDN = 3'b010;
  localparam RUP = 3'b011;
  localparam RMM = 3'b100;

  constraint LW_SW {!(f_LW && f_SW);}
  constraint calculation_method {f_funct_7 == ADD || f_funct_7 == MUL || f_funct_7 == SUB;}
  constraint operand {dload_ext[30:23] != 8'b11111111;}
  constraint destination {f_rd != f_rs1; f_rd != f_rs2;}
  constraint rounding {f_frm_in == RNE || f_frm_in == RZE || f_frm_in == RDN || f_frm_in == RUP || f_frm_in == RMM;}

  function new(string name = "FPU_transaction");
    super.new(name);
  endfunction: new

endclass //FPU_transaction

class FPU_response extends uvm_sequence_item;
  // logic [4:0] f_flags; //a combination of NV, DZ, OF, UF, NX
  logic [4:0] f_rs2; //register selection 2. Select operand 2 from a register
  logic [31:0] FPU_all_out; //output when f_SW is asserted
  // logic [2:0] f_frm_out; //frm outputed by register file TODO: confusing
  
  `uvm_object_utils_begin(FPU_response)
    // `uvm_field_int(f_flags, UVM_DEFAULT)
    `uvm_field_int(FPU_all_out, UVM_DEFAULT)
    `uvm_field_int(f_rs2, UVM_DEFAULT)
    // `uvm_field_int(f_frm_out, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "FPU_response");
    super.new(name);
  endfunction: new

endclass //FPU_response

class registerFile;
  parameter NUM_REGS = 32;
  logic [31:0] [NUM_REGS-1:0] registers;

  function void write(logic[4:0]rd, logic[31:0] val);
    registers[rd] = val;
  endfunction

  function logic[31:0] read(logic[4:0]rd);
    return registers[rd];
  endfunction

  function void initialize();
    for(int lcv = 0; lcv < 32; lcv++) begin
      registers[lcv] = 0;
    end
  endfunction
endclass //registerFile

`endif
