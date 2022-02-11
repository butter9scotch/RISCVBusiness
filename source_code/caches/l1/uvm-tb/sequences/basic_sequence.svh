`ifndef BASIC_SEQUENCE
`define BASIC_SEQUENCE

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "cpu_transaction.svh"

/** Sequence to test read after writes to the same location */
class basic_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(basic_sequence)
  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    cpu_transaction req_item;
    bit isWrite;
    word_t prevAddr;
    
    req_item = cpu_transaction::type_id::create("req_item");
    isWrite = '1; //write, read, write, ...
    prevAddr = '0;
    
    // repeat twenty randomized test cases
    repeat(10) begin
      start_item(req_item);
      if(!req_item.randomize() with {rw == isWrite; if (~isWrite) addr == prevAddr;}) begin
        `uvm_fatal("Randomize Error", "not able to randomize")
      end

      `uvm_info("Addr", $sformatf("rw: %d, addr: %x",req_item.rw, req_item.addr), UVM_LOW)

      isWrite = ~isWrite; //toggle read/write
      prevAddr = req_item.addr;

      finish_item(req_item);
    end
  endtask: body
endclass: basic_sequence

`endif