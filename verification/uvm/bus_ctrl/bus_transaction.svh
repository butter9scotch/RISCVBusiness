`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "dut_params.svh"

class bus_transaction extends uvm_sequence_item;

  localparam TRANS_SIZE dut_params::WORD_W * dut_params::BLOCK_SIZE_WORDS;

  rand bit [dut_params::NUM_CPUS_USED - 1: 0] [1023:0] idle;
  rand bit [dut_params::NUM_CPUS_USED - 1: 0] [1023:0] [dut_params::WORD_W - 1: 0] daddr;
  rand bit [dut_params::NUM_CPUS_USED - 1: 0] [1023:0] rw;
  rand bit [dut_params::NUM_CPUS_USED - 1: 0] [1023:0] [TRANS_SIZE - 1: 0] dstore;
  rand bit [dut_params::NUM_CPUS_USED - 1: 0] [1023:0] [TRANS_SIZE - 1: 0] dload;
  rand bit [dut_params::NUM_CPUS_USED - 1: 0] [1023:0] exclusive;
 
  
  //TODO: YOU MAY WANT TO RECONSIDER HOW MANY OF THESE FIELDS YOU INCLUDE FOR PRINTING
  // NOTE: EXAMPLE OF NOT PRINTING CERTAIN FIELDS BELOW
  // `uvm_field_int(haddr, UVM_NOCOMPARE | UVM_NOPRINT)

  `uvm_object_utils_begin(bus_transaction)
    `uvm_field_int(idle, UVM_DEFAULT)
    `uvm_field_int(daddr, UVM_DEFAULT)
    `uvm_field_int(rw, UVM_DEFAULT)
    `uvm_field_int(dstore, UVM_DEFAULT)
    `uvm_field_int(dload, UVM_DEFAULT)
    `uvm_field_int(exclusive, UVM_DEFAULT)
  `uvm_object_utils_end

  function new(string name = "bus_transaction");
    super.new(name);
  endfunction : new

endclass : bus_transaction

`endif
