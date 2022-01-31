`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

class transaction #(parameter NUM_BITS = 4) extends uvm_sequence_item;
  rand bit [NUM_BITS - 1:0] rollover_value;
  rand int num_clk; // number of clk cycles that counter_enable keeps on
  bit [NUM_BITS - 1:0] result_count_out;
  bit result_flag;

  `uvm_object_utils_begin(transaction)
    `uvm_field_int(rollover_value, UVM_NOCOMPARE)
    `uvm_field_int(num_clk, UVM_NOCOMPARE)
    `uvm_field_int(result_count_out, UVM_DEFAULT)
    `uvm_field_int(result_flag, UVM_DEFAULT)
  `uvm_object_utils_end

  constraint rollover {rollover_value != 0; rollover_value != 1;}
  constraint clk_number{num_clk > 0; num_clk < 20;}

  function new(string name = "transaction");
    super.new(name);
  endfunction: new

  // comparison between two transaction object
  // if two transactions are the same, return 1 else return 
  function int input_equal(transaction tx);
    int result;
    if((rollover_value == tx.rollover_value) && (num_clk == tx.num_clk)) begin
      result = 1;
      return result;
    end
    result = 0;
    return result;
  endfunction

endclass //transaction

`endif
