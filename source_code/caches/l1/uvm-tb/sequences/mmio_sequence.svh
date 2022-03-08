`ifndef MMIO_SEQUENCE_SVH
`define MMIO_SEQUENCE_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "cpu_transaction.svh"

`include "dut_params.svh"

/** Sequence to test read after writes to the same location */
class mmio_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(mmio_sequence)
  function new(string name = "");
    super.new(name);
  endfunction: new

  rand int N;  // total number of processor side transactions

  task body();
    cpu_transaction req_item;

    req_item = cpu_transaction::type_id::create("req_item");

    `uvm_info(this.get_name(), $sformatf("Creating sequence with size N=%0d", N), UVM_LOW)
    
    repeat(N) begin
      start_item(req_item);

      // writes.shuffle();
      if(!req_item.randomize()) begin
        `uvm_fatal("Randomize Error", "not able to randomize")
      end

      `uvm_info(this.get_name(), $sformatf("Generated New Sequence Item:\n%s", req_item.sprint()), UVM_HIGH)

      finish_item(req_item);
    end
  endtask: body
endclass: mmio_sequence

`endif