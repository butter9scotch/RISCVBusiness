import uvm_pkg::*;
`include "uvm_macros.svh"
`include "tb_FPU_agent.svh"
`include "FPU_if.svh"
`include "tb_FPU_comparator.svh"
`include "tb_FPU_predictor.svh"
`include "tb_FPU_transaction.svh"

class FPU_env extends uvm_env;
  `uvm_component_utils(FPU_env)
  FPU_agent FPU_agt;

  FPU_predictor FPU_pred;
  FPU_comparator FPU_comp;

  registerFile sim_rf; //simulated register file
  transactionSeq tx_seq;
  
  function new(string name = "FPU_env", uvm_component parent = null);
		super.new(name, parent);
	endfunction

  function void build_phase(uvm_phase phase);
    sim_rf = new();
    tx_seq = new();
    sim_rf.initialize();
    FPU_agt = FPU_agent::type_id::create("FPU_agt", this);
    FPU_pred = FPU_predictor::type_id::create("FPU_pred", this);
    FPU_comp = FPU_comparator::type_id::create("FPU_comp", this);
    //connect simulated register file
    FPU_pred.sim_rf = sim_rf;
    FPU_comp.sim_rf = sim_rf;

    //connect transaction queues
    FPU_pred.tx_seq = tx_seq;
    FPU_comp.tx_seq = tx_seq;
  endfunction

  function void connect_phase(uvm_phase phase);
    FPU_agt.mon.FPU_ap.connect(FPU_pred.analysis_export); //connect monitor to predictor
    // FPU_pred.ap_pred.connect(FPU_comp.transaction_export); //connect predictor to comparator
    FPU_agt.mon.FPU_result_ap.connect(FPU_comp.actual_export); //connect monitor to comparator
  endfunction


endclass: FPU_env
