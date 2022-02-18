`ifndef MEM_MONITOR_SVH
`define MEM_MONITOR_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "bus_monitor.svh"
`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class mem_monitor extends bus_monitor;
  `uvm_component_utils(mem_monitor)
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  // Build Phase - Get handle to virtual if from config_db
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if( !uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "mem_cif", cif) ) begin
      `uvm_fatal("Mem Monitor/cif", "No virtual interface specified for this test instance");
		end
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "l1_bus_if", bus_if) ) begin
      `uvm_fatal("Mem Monitor/cpu_bus_if", "No virtual interface specified for this test instance");
		end
    `uvm_info(this.get_name(), "pulled <l1_bus_if> from db", UVM_FULL)
  endfunction: build_phase

endclass: mem_monitor

`endif