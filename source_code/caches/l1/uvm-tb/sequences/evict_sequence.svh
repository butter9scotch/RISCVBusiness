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
  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    cpu_transaction req_item;
    
    logic [31 - `L1_TAG_BITS:0] index;
    
    req_item = cpu_transaction::type_id::create("req_item");
    
    repeat(2) begin
      //TODO: Same index but different tag
      $display("tag bits: %d", `L1_TAG_BITS);
      for (int i = 0; i < 2*`L1_ASSOC; i++) begin
        start_item(req_item);
        if(!req_item.randomize() with {
          if (i != 0) {
            addr[31 - `L1_TAG_BITS:0] == index;
          }
          rw == '1;
          }) begin
          `uvm_fatal("Randomize Error", "not able to randomize")
        end
        index = req_item.addr[31 - `L1_TAG_BITS:0];

        `uvm_info(this.get_name(), $sformatf("Generated New Sequence Item:\n%s", req_item.sprint()), UVM_HIGH)

        finish_item(req_item);
      end
    end
  endtask: body
endclass: evict_sequence

`endif