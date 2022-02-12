`ifndef BUS_PREDICTOR_SHV
`define BUS_PREDICTOR_SHV

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"
`include "cpu_transaction.svh"

class bus_predictor extends uvm_subscriber #(cpu_transaction);
  `uvm_component_utils(bus_predictor) 

  uvm_analysis_port #(cpu_transaction) pred_ap;
  cpu_transaction pred_tx;

  word_t memory [word_t]; //software cache

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    pred_ap = new("pred_ap", this);
  endfunction


  function void write(cpu_transaction t);
    // t is the transaction sent from monitor
    pred_tx = cpu_transaction::type_id::create("pred_tx", this);
    pred_tx.copy(t);

    if (pred_tx.rw) begin
      // 1 -> write
      memory[pred_tx.addr] = pred_tx.data;
    end else begin
      // 0 -> read
      pred_tx.data = memory[pred_tx.addr];
    end

    //TODO: REPLACE WITH WITH UVM_INFO
    $displayh("memory: %p", memory);

    // after prediction, the expected output send to the scoreboard 
    pred_ap.write(pred_tx);
  endfunction: write

endclass: bus_predictor

`endif