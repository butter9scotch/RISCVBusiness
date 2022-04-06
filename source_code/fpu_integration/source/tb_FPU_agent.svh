import uvm_pkg::*;
`include "uvm_macros.svh"
// `include "tb_FPU_sequencer.svh"
`include "tb_FPU_driver.svh"
`include "tb_FPU_monitor.svh"
// `include "FPU_result_monitor.svh"

class FPU_agent extends uvm_agent;
  `uvm_component_utils(FPU_agent)

  FPU_sequencer sqr;
  FPU_driver drv;
  FPU_monitor mon;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);   
    sqr = FPU_sequencer::type_id::create("sqr", this);
    drv = FPU_driver::type_id::create("drv", this);
    mon = FPU_monitor::type_id::create("mon", this);
    mon.set_report_verbosity_level_hier (UVM_NONE);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    uvm_report_info("FPU_agent::", "connect_phase, Connected driver to sequencer");
  endfunction

endclass: FPU_agent


