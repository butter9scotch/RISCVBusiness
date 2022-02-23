`ifndef NOMINAL_SEQUENCE_SVH
`define NOMINAL_SEQUENCE_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "cpu_transaction.svh"

/** Sequence to test read after writes to the same location */
class nominal_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(nominal_sequence)
  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    cpu_transaction req_item;
    bit isWrite;
    word_t prevAddr;
    int N;

    N = 6; //NOTE: this should be even

    req_item = cpu_transaction::type_id::create("req_item");
    isWrite = '1; //write, read, write, ...
    prevAddr = '0;
    
    // repeat twenty randomized test cases
    repeat(N) begin
      start_item(req_item);
      if(!req_item.randomize() with {
        rw == isWrite;
        if (~isWrite) {
          addr == prevAddr;
          data == 'hdada_0bad;
        }
        }) begin
        `uvm_fatal("Randomize Error", "not able to randomize")
      end

      isWrite = ~isWrite; //toggle read/write
      prevAddr = req_item.addr;

      `uvm_info(this.get_name(), $sformatf("Generated New Sequence Item:\n%s", req_item.sprint()), UVM_HIGH)

      finish_item(req_item);
    end
  endtask: body
endclass: nominal_sequence

`endif