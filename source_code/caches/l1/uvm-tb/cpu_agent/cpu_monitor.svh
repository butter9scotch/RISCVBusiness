import uvm_pkg::*;
`include "uvm_macros.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class cpu_monitor extends uvm_monitor;
  `uvm_component_utils(cpu_monitor)

  virtual l1_cache_wrapper_if cif;
  virtual generic_bus_if proc_gen_bus_if;

  uvm_analysis_port #(cpu_transaction) cpu_ap;
  cpu_transaction prev_tx; // to see if a new transaction has been sent
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    cpu_ap = new("cpu_ap", this);
  endfunction: new

  // Build Phase - Get handle to virtual if from config_db
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if( !uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cif", cif) ) begin
      `uvm_fatal("CPU Monitor/cif", "No virtual interface specified for this test instance");
		end
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "proc_gen_bus_if", proc_gen_bus_if) ) begin
      `uvm_fatal("CPU Monitor/proc_gen_bus_if", "No virtual interface specified for this test instance");
		end
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    //TODO: NEEDS IMPLEMENTATION
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

endclass: cpu_monitor
