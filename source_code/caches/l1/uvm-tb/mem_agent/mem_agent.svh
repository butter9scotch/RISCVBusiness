`ifndef MEM_AGENT_SHV
`define MEM_AGENT_SHV

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "mem_monitor.svh"

class mem_agent extends uvm_agent;
  `uvm_component_utils(mem_agent)
  mem_monitor mon;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);   
    mon = mem_monitor::type_id::create("MEM_MON", this);
    `uvm_info(this.get_name(), $sformatf("Created <%s>", mon.get_name()), UVM_FULL)
  endfunction

endclass: mem_agent

`endif