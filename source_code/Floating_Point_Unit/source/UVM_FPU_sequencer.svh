import uvm_pkg::*;
`include "uvm_macros.svh"

`include "FPU_transaction.svh"

class FPU_sequence extends uvm_sequence #(FPU_transaction);
  `uvm_object_utils(FPU_sequence)
  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    FPU_transaction req_item;
    req_item = FPU_transaction::type_id::create("req_item");
    start_item(req_item);
    req_item.fp1 = '0;
    req_item.fp2 = '0;
    req_item.frm = '0;
    req_item.funct7 = 7'b0100000;
    req_item.fp_out = '0;
    req_item.flags = '0;
    finish_item(req_item);

    start_item(req_item);
    req_item.fp1 = 32'b11000010101010000011011111001111;
    req_item.fp2 = 32'b00000000000000000000000000000000;
    req_item.frm = '1;
    req_item.funct7 = 7'b0100000;
    req_item.fp_out = '1;
    req_item.flags = '1;
    finish_item(req_item);

    repeat(30) begin
      start_item(req_item);
      if(!req_item.randomize()) begin
        `uvm_fatal("FPU_seq", "not able to randomize")
      end
      // req_item.randomize();
      finish_item(req_item);
    end

  endtask: body
endclass //FPU_sequence

class FPU_sequencer extends uvm_sequencer#(FPU_transaction);

   `uvm_component_utils(FPU_sequencer)
 
   function new(input string name= "FPU_sequencer", uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

endclass : FPU_sequencer
