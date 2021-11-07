`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH

import rv32v_types_pkg::*;
import rv32i_types_pkg::*;

class instruction;

  bit [4:0] vd;
  bit [4:0] vs1;
  bit [4:0] vs2;
  opcode_t op;

  bit vm;
  vfunct3_t [2:0] vfunct3; 
  vopm_t vfunct6_vopm;
  vopi_t vfunct6_vopi;
  bit [31:0] instr; 

  function new ();
  endfunction

  function bit [31:0] get_instr();
    return {vfunct6_vopi, vm, vs2, vs1, vfunct3, vd, op};
  endfunction

endclass //transaction

class randinstruction;

  rand bit [4:0] vd;
  rand bit [4:0] vs1;
  rand bit [4:0] vs2;
  rand opcode_t op;

  bit vm;
  vfunct3_t [2:0] vfunct3; 
  vopm_t vfunct6_vopm;
  vopi_t vfunct6_vopi;
  bit [31:0] instr; 

  constraint op_types { op inside {VECTOR}; }


  function new ();
  endfunction

  function bit [31:0] get_instr();
    return {vfunct6_vopi, vm, vs2, vs1, vfunct3, vd, op};
  endfunction

endclass //transaction

`endif
