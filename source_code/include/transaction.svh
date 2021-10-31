`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH

import rv32v_types_pkg::*;
import rv32i_types_pkg::*;
// import uvm_pkg::*;
// `include "uvm_macros.svh"


class transaction;
  // import rv32v_types_pkg::*;
  // import rv32i_types_pkg::*;

  rand bit [6:0] op;
  rand bit [4:0] vd;
  rand bit [2:0] vfunct3; 
  rand bit [4:0] vs1;
  rand bit [4:0] vs2;
  rand bit vm;
  rand bit [6:0] vfunct6_vopi;
  rand bit [6:0] vfunct6_vopm;
  rand bit [31:0] instr; 


  // constraint rollover {rollover_value != 0; rollover_value != 1;}
  // constraint clk_number{num_clk > 0; num_clk < 20;}

  function new(string name = "transaction");
    super.new(name);
  endfunction: new
 

  // comparison between two transaction object
  // if two transactions are the same, return 1 else return 
  function int get_instr();
    return {vfunct6_vopi, vm, vs2, vs1, vfunct3, vd, op};
  endfunction

endclass //transaction

`endif
