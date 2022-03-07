`ifndef MASTER_SEQUENCE_SVH
`define MASTER_SEQUENCE_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "dut_params.svh"

`include "evict_sequence.svh"
`include "nominal_sequence.svh"

`include "cpu_transaction.svh"

class master_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(master_sequence)

  rand bit order;     // ordering of evict/nominal sequences
  rand bit iterations;

  evict_sequence evt_seq;
  nominal_sequence nom_seq;

  function new(string name = "");
    super.new(name);
    evt_seq = evict_sequence::type_id::create("evt_seq");
    nom_seq = nominal_sequence::type_id::create("nom_seq");
  endfunction: new

  //TODO: IMPLEMENT THIS IN MASTER SEQUENCE
  function void post_randomize();
    evt_seq.randomize();
    nom_seq.randomize();
  endfunction

  task body();
    cpu_transaction req_item;

    repeat(1) begin
      // evt_seq.start(env.cpu_agt.sqr);
      // if(!nom_seq.randomize() with {
      //   N inside {[10:20]};
      //   }) begin
      //   `uvm_fatal("Randomize Error", "not able to randomize")
      // end
      // nom_seq.start(env.cpu_agt.sqr);
    end
  endtask: body
endclass: master_sequence

`endif