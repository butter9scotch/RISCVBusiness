`ifndef MASTER_SEQUENCE_SVH
`define MASTER_SEQUENCE_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "dut_params.svh"

`include "evict_sequence.svh"
`include "nominal_sequence.svh"

`include "cpu_transaction.svh"

class sub_master_sequence;
  rand bit order;
  rand int evt_max_n;
  rand int nom_max_n;

  //TODO: CHANGE THESE TO MORE CONFIGURABLE PARAMS
  constraint max {
    evt_max_n > 0; evt_max_n < 10; 
    nom_max_n > 0; nom_max_n < 20;
  }

  function void show();
    `uvm_info("sub_master_seq", $sformatf("order: %b, evt_max_n: %0d, nom_max_n: %0d", order, evt_max_n, nom_max_n), UVM_LOW);
  endfunction
endclass: sub_master_sequence

class master_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(master_sequence)
  `uvm_declare_p_sequencer(cpu_sequencer)

  rand int iterations;

  constraint range {
    iterations > 0; iterations < 10;
  }

  sub_master_sequence seq_param;

  evict_sequence evt_seq;
  nominal_sequence nom_seq;

  function new(string name = "");
    super.new(name);
    evt_seq = evict_sequence::type_id::create("evt_seq");
    nom_seq = nominal_sequence::type_id::create("nom_seq");
    seq_param = new();
  endfunction: new

  function void sub_randomize();
    //randomize sub-sequences
    if(!evt_seq.randomize() with {
      N inside {[0:seq_param.nom_max_n]};
      }) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end

    if(!nom_seq.randomize() with {
      N inside {[0:seq_param.nom_max_n]};
      }) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end
  endfunction

  task body();
    cpu_transaction req_item;

    `uvm_info(this.get_name(), $sformatf("running %0d iterations", iterations), UVM_LOW)

    repeat(iterations) begin
      seq_param.randomize();
      seq_param.show();

      sub_randomize();
      
      if (seq_param.order) begin
        evt_seq.start(p_sequencer);
        nom_seq.start(p_sequencer);
      end else begin
        nom_seq.start(p_sequencer);
        evt_seq.start(p_sequencer);
      end
    end
  endtask: body
endclass: master_sequence

`endif