import uvm_pkg::*;
`include "uvm_macros.svh"

`include "FPU_if.svh"

class FPU_driver extends uvm_driver#(FPU_transaction);
  `uvm_component_utils(FPU_driver)

  protected virtual FPU_if vif;
  int tx_number;

  function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if( !uvm_config_db#(virtual FPU_if)::get(this, "", "vif", vif) ) begin
      `uvm_fatal("FPU/DRV/NOVIF", "No virtual interface specified for this test instance");
		end
    tx_number = -1;
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    FPU_transaction req_item;

    forever begin 
      seq_item_port.get_next_item(req_item);
      @(posedge vif.clk);
      tx_number++;
      vif.f_LW = req_item.f_LW;
      vif.f_SW = req_item.f_SW;
      vif.f_rs1 = req_item.f_rs1;
      vif.f_rs2 = req_item.f_rs2;
      vif.f_rd = req_item.f_rd;
      vif.f_frm_in = req_item.f_frm_in;
      vif.f_funct_7 = req_item.f_funct_7;
      vif.dload_ext = req_item.dload_ext;
      vif.transaction_number = tx_number;
      //wait two clock cycle
      @(posedge vif.clk);
      @(posedge vif.clk);


      seq_item_port.item_done();
    end
  endtask: run_phase

endclass: FPU_driver
