import uvm_pkg::*;
`include "uvm_macros.svh"

`include "FPU_if.svh"


class FPU_monitor extends uvm_monitor;
  `uvm_component_utils(FPU_monitor)
  virtual FPU_if vif;

  uvm_analysis_port #(FPU_transaction) FPU_ap;
  uvm_analysis_port #(FPU_response) FPU_result_ap;
  FPU_transaction prev_tx; //to see if a new transaction has been sent
  
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    FPU_ap = new("FPU_ap", this);
    FPU_result_ap = new("FPU_result_ap", this);
  endfunction: new

  //Build Phase - Get handle to virtual if from agent/config_db
  virtual function void build_phase(uvm_phase phase);
    virtual FPU_if FPU_if_temp;
    if (!uvm_config_db#(virtual FPU_if)::get(this, "", "vif", FPU_if_temp)) begin
      `uvm_fatal("FPU/MON/NOVIF", "No virtual interface specified for this monitor instance")
    end
    vif = FPU_if_temp;
    prev_tx = FPU_transaction::type_id::create("prev_tx");
  endfunction

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      FPU_transaction tx;
      FPU_response resp;
      @(posedge vif.clk);
      tx = FPU_transaction::type_id::create("tx");
      tx.f_LW = vif.f_LW;
      tx.f_SW = vif.f_SW;
      tx.f_rs1 = vif.f_rs1;
      tx.f_rs2 = vif.f_rs2;
      tx.f_rd = vif.f_rd;
      tx.f_frm_in = vif.f_frm_in;
      tx.f_funct_7 = vif.f_funct_7;
      tx.dload_ext = vif.dload_ext;


      if (!tx.compare(prev_tx)) begin
        FPU_ap.write(tx);
        @(posedge vif.clk);
        @(posedge vif.clk);
        if(tx.f_SW) begin
          resp = FPU_response::type_id::create("resp");
          resp.FPU_all_out = vif.FPU_all_out;
          resp.f_rs2 = vif.f_rs2;
          FPU_result_ap.write(resp);
        end
        prev_tx.copy(tx);
      end
    end
  endtask: run_phase


endclass: FPU_monitor
