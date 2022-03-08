`ifndef EVICT_SEQUENCE_SVH
`define EVICT_SEQUENCE_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "cpu_transaction.svh"

`include "dut_params.svh"

/** Sequence to test read after writes to the same location */
class evict_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(evict_sequence)

  rand int N; //number of iterations of eviction events

  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    cpu_transaction req_item;
    int N_reps; // used to back calculate proper repetitions to used when combined with inner for loop
    logic [`L1_INDEX_BITS-1:0] index;
    
    req_item = cpu_transaction::type_id::create("req_item");

    N_reps = N / (`L1_ASSOC + 1);

    `uvm_info(this.get_name(), $sformatf("Requested size: %0d; Creating sequence with size N=%0d", N, N_reps * (`L1_ASSOC + 1)), UVM_LOW)
    
    repeat(N_reps) begin
      for (int i = 0; i < `L1_ASSOC + 1; i++) begin
        start_item(req_item);
        if(!req_item.randomize() with {
          if (i != 0) {
            addr[`L1_INDEX_BITS-1:0] == index;
          }
          rw == '1;
          }) begin
          `uvm_fatal("Randomize Error", "not able to randomize")
        end
        index = req_item.addr[`L1_INDEX_BITS:0];

        `uvm_info(this.get_name(), $sformatf("Generated New Sequence Item:\n%s", req_item.sprint()), UVM_HIGH)

        finish_item(req_item);
      end
    end
  endtask: body
endclass: evict_sequence

`endif