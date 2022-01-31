import uvm_pkg::*;
`include "uvm_macros.svh"
`include "transaction.svh"

class predictor extends uvm_subscriber #(transaction);
  `uvm_component_utils(predictor) 

  uvm_analysis_port #(transaction) pred_ap;
  transaction output_tx;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    pred_ap = new("pred_ap", this);
  endfunction


  function void write(transaction t);
    //TODO: NEEDS IMPLEMENTATION
    // // t is the transaction sent from monitor
    // output_tx = transaction#(4)::type_id::create("output_tx", this);
    // output_tx.copy(t);
    // // calculate the expected count_out
    // output_tx.result_count_out = 0;
    // for (int lcv = 0; lcv < t.num_clk; lcv++) begin
    //   output_tx.result_count_out++;
    //   if (output_tx.result_count_out == t.rollover_value + 1) begin
    //     output_tx.result_count_out = 1;
    //   end
    // end

    // // calculate the expected rollover_flag
    // if (output_tx.result_count_out == t.rollover_value) begin
    //   output_tx.result_flag = 1;
    // end else begin
    //   output_tx.result_flag = 0;
    // end

    // // after prediction, the expected output send to the scoreboard 
    // pred_ap.write(output_tx);
  endfunction: write

endclass: predictor

