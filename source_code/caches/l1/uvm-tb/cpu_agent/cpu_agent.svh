`ifndef CPU_AGENT_SVH
`define CPU_AGENT_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "evict_sequence.svh"
`include "raw_sequence.svh"
`include "cpu_driver.svh"
`include "cpu_monitor.svh"

typedef uvm_sequencer#(cpu_transaction) cpu_sequencer;

class cpu_agent extends uvm_agent;
  `uvm_component_utils(cpu_agent)
  cpu_sequencer sqr;
  cpu_driver drv;
  cpu_monitor mon;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);   
    sqr = cpu_sequencer::type_id::create("CPU_SQR", this);
    drv = cpu_driver::type_id::create("CPU_DRV", this);
    mon = cpu_monitor::type_id::create("CPU_MON", this);
    `uvm_info(this.get_name(), $sformatf("Created <%s>, <%s>, <%s>", drv.get_name(), sqr.get_name(), mon.get_name()), UVM_FULL)
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    `uvm_info(this.get_name(), $sformatf("Connected <%s> to <%s>", drv.get_name(), sqr.get_name()), UVM_FULL)
  endfunction

endclass: cpu_agent

`endif