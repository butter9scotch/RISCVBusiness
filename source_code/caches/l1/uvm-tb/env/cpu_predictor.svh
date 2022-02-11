import uvm_pkg::*;
`include "uvm_macros.svh"
`include "cpu_transaction.svh"

class cpu_predictor extends uvm_subscriber #(cpu_transaction);
  `uvm_component_utils(cpu_predictor) 

  uvm_analysis_port #(cpu_transaction) pred_ap;
  cpu_transaction output_tx;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    pred_ap = new("pred_ap", this);
  endfunction


  function void write(cpu_transaction t);
    // t is the transaction sent from monitor
    output_tx = cpu_transaction::type_id::create("output_tx", this);
    
    // TODO: IMPLEMENT PREDICTOR LOGIC

    `uvm_info("CPU PREDICTOR", "Received new transaction", UVM_LOW)

    // after prediction, the expected output send to the scoreboard 
    pred_ap.write(output_tx);
  endfunction: write

endclass: cpu_predictor

