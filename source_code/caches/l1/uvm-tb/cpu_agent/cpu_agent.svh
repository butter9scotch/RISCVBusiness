`ifndef CPU_AGENT_SVH
`define CPU_AGENT_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
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
    sqr = cpu_sequencer::type_id::create("sqr", this);
    drv = cpu_driver::type_id::create("drv", this);
    mon = cpu_monitor::type_id::create("mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

endclass: cpu_agent

`endif