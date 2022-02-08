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
    repeat(20) begin
      start_item(req_item);
      if(!req_item.randomize()) begin
        // if the transaction is unable to be randomized, send a fatal message
        `uvm_fatal("basic sequence", "not able to randomize")
      end

      req_item.rw = isWrite;
      if (~isWrite) begin
        req_item.addr = prevAddr;
      end

      isWrite = ~isWrite; //toggle read/write
      prevAddr = req_item.addr;

      finish_item(req_item);
    end
  endtask: body
endclass: basic_sequence
