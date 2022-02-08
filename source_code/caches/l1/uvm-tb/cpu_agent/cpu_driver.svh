import uvm_pkg::*;
`include "uvm_macros.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class cpu_driver extends uvm_driver#(cpu_transaction);
  `uvm_component_utils(cpu_driver)

  virtual l1_cache_wrapper_if cif;
  virtual generic_bus_if cpu_bus_if;

  function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if( !uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cif", cif) ) begin
      `uvm_fatal("CPU_Driver/cif", "No virtual interface specified for this test instance");
		end
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "cpu_bus_if", cpu_bus_if) ) begin
      `uvm_fatal("CPU_Driver/cpu_bus_if", "No virtual interface specified for this test instance");
		end
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    //TODO: NEEDS IMPLEMENTATION
    // transaction req_item;
    // vif.check = 0;

    // forever begin 
    //   seq_item_port.get_next_item(req_item);
    //   DUT_reset();
    //   vif.rollover_val = req_item.rollover_value;
    //   vif.enable_time = req_item.num_clk;
    //   vif.count_enable = 1;
    //   repeat(req_item.num_clk) begin
    //     @(posedge vif.clk);
    //   end
    //   vif.count_enable = 0;
    //   #(0.2);
    //   vif.check = 1;
    //   @(posedge vif.clk);
    //   seq_item_port.item_done();
    // end
  endtask: run_phase

  task DUT_reset();
    @(posedge cif.CLK);
    cif.nRST = 1;
    cif.clear = 0;
    cif.flush = 0;
    @(posedge cif.CLK);
    cif.nRST = 0;
    @(posedge cif.CLK);
    cif.nRST = 1;
    @(posedge cif.CLK);
  endtask

endclass: cpu_driver
