import uvm_pkg::*;
`include "uvm_macros.svh"
// `include "counter_if.svh"
//TODO: NEEDS IMPLEMENTATION
class monitor extends uvm_monitor;
  `uvm_component_utils(monitor)

  // virtual counter_if vif;

  uvm_analysis_port #(transaction) counter_ap;
  uvm_analysis_port #(transaction) result_ap;
  transaction prev_tx; // to see if a new transaction has been sent
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    counter_ap = new("counter_ap", this);
    result_ap = new("result_ap", this);
  endfunction: new

  // Build Phase - Get handle to virtual if from config_db
  virtual function void build_phase(uvm_phase phase);
    // if (!uvm_config_db#(virtual counter_if)::get(this, "", "counter_vif", vif)) begin
    //   `uvm_fatal("monitor", "No virtual interface specified for this monitor instance")
    // end
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    // prev_tx = transaction#(4)::type_id::create("prev_tx");
    // forever begin
    //   transaction tx;
    //   @(posedge vif.clk);
    //   // captures activity between the driver and DUT
    //   tx = transaction#(4)::type_id::create("tx");
    //   tx.rollover_value = vif.rollover_val;
    //   tx.num_clk = vif.enable_time;

    //   // check if there is a new transaction
    //   if (!tx.input_equal(prev_tx) && tx.rollover_value !== 'z) begin
    //     // send the new transaction to predictor though counter_ap
    //     counter_ap.write(tx);
    //     // wait until check is asserted
    //     while(!vif.check) begin
    //       @(posedge vif.clk);
    //     end
    //     // capture the responses from DUT and send it to scoreboard through result_ap
    //     tx.result_count_out = vif.count_out;
    //     tx.result_flag = vif.rollover_flag;
    //     result_ap.write(tx);
    //     prev_tx.copy(tx);
    //   end
    // end
  endtask: run_phase

endclass: monitor
