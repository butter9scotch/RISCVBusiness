import uvm_pkg::*;
`include "uvm_macros.svh"

`include "cpu_transaction.svh"

class basic_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(basic_sequence)
  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    cpu_transaction req_item;
    req_item = cpu_transaction::type_id::create("req_item");
    
    // repeat twenty randomized test cases
    repeat(20) begin
      start_item(req_item);
      if(!req_item.randomize()) begin
        // if the transaction is unable to be randomized, send a fatal message
        `uvm_fatal("sequence", "not able to randomize")
      end
      finish_item(req_item);
    end
  endtask: body
endclass: basic_sequence
