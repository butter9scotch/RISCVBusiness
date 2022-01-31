import uvm_pkg::*;
`include "uvm_macros.svh"

`include "transaction.svh"

class counter_sequence extends uvm_sequence #(transaction);
  `uvm_object_utils(counter_sequence)
  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    transaction req_item;
    req_item = transaction#(4)::type_id::create("req_item");
    
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
endclass //sequence

class sequencer extends uvm_sequencer#(transaction);

   `uvm_component_utils(sequencer)
 
   function new(input string name= "sequencer", uvm_component parent=null);
      super.new(name, parent);
   endfunction : new
endclass : sequencer
