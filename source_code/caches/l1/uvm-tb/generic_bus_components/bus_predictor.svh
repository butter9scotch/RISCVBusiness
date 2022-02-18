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
    string str;
    // t is the transaction sent from monitor
    pred_tx = cpu_transaction::type_id::create("pred_tx", this);
    pred_tx.copy(t);

    `uvm_info(this.get_name(), $sformatf("Recevied Transaction:\n%s", pred_tx.sprint()), UVM_HIGH)

    $swriteh(str,"memory before:\n%p",memory);
    `uvm_info(this.get_name(), str, UVM_HIGH)

    if (pred_tx.rw) begin
      // 1 -> write
      memory[pred_tx.addr] = pred_tx.data;
    end else begin
      // 0 -> read
      pred_tx.data = read_mem(pred_tx.addr);
    end

    $swriteh(str,"memory after:\n%p",memory);
    `uvm_info(this.get_name(), str, UVM_HIGH)

    // after prediction, the expected output send to the scoreboard 
    pred_ap.write(pred_tx);
  endfunction: write

  virtual function word_t read_mem(word_t addr);
    // `uvm_info(this.get_name(), "Using Bus Predictor read_mem()", UVM_FULL)
    return memory[addr];
  endfunction: read_mem

endclass: bus_predictor

`endif