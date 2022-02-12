`ifndef MEM_MONITOR_SVH
`define MEM_MONITOR_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class mem_monitor extends uvm_monitor;
  `uvm_component_utils(mem_monitor)

  //TODO: MERGE THIS INTO GENERIC BUS MONITOR CLASS TO SHARE CODE WITH CPU_MONITOR

  virtual l1_cache_wrapper_if cif;
  virtual generic_bus_if cpu_bus_if;

  uvm_analysis_port #(cpu_transaction) req_ap;
  uvm_analysis_port #(cpu_transaction) resp_ap;
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    req_ap = new("req_ap", this);
    resp_ap = new("resp_ap", this);
  endfunction: new

  // Build Phase - Get handle to virtual if from config_db
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if( !uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cif", cif) ) begin
      `uvm_fatal("Mem Monitor/cif", "No virtual interface specified for this test instance");
		end
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "l1_bus_if", l1_bus_if) ) begin
      `uvm_fatal("Mem Monitor/l1_bus_if", "No virtual interface specified for this test instance");
		end
  endfunction: build_phase

endclass: cpu_monitor

`endif