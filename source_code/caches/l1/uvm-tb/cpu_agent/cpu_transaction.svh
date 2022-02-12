`ifndef CPU_TRANSACTION_SVH
`define CPU_TRANSACTION_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;
`include "uvm_macros.svh"
`include "cache_env.svh"


class cpu_transaction extends uvm_sequence_item;

  rand bit rw; // 0 -> read; 1 -> write
  //FIXME: DO WE NEED TO WORRY ABOUT I AND D CACHES?
  // logic instr_data; // 0 -> instr cache, 1 -> data cache
  rand word_t addr;
  rand word_t data;
  // logic p; //processor number p0 or p1 //FIXME: DO WE WANT TO TEST WITH MULTIPLE PROCESSORS?
  
  //TODO: ADD BYTE ENABLE
  // Byte enable logic
  // 4bits, one bit always high
  // 0th bit is one byte
  // 1th bit is 16 bits...
  //TODO: ADD CLEAR
  //TODO: ADD FLUSH

  `uvm_object_utils_begin(cpu_transaction)
      `uvm_field_int(rw, UVM_ALL_ON)
      // `uvm_field_int(instr_data, UVM_ALL_ON)
      `uvm_field_int(addr, UVM_ALL_ON)
      `uvm_field_int(data, UVM_ALL_ON)
      // `uvm_field_int(p, UVM_ALL_ON)
  `uvm_object_utils_end

  // constraint clk_number{num_clk > 0; num_clk < 20;}
    constraint usable_addr {addr >= '0; addr < 32'h8000_0000;} //TODO: PULL NON_START ADDR INTO CONFIG FILE
    // constraint usable_addr {addr >= '0; addr < CONFIG_NONCACHE_START_ADDR;}

  function new(string name = "cpu_transaction");
    super.new(name);
  endfunction: new

endclass: cpu_transaction

`endif
