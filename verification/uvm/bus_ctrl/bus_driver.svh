`ifndef AHB_BUS_DRIVER_SVH
`define AHB_BUS_DRIVER_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "bus_ctrl_if.sv"

class bus_driver extends uvm_driver #(bus_transaction);
  `uvm_component_utils(bus_driver)

  virtual bus_ctrl_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if (!uvm_config_db#(virtual bus_ctrl_if)::get(this, "", "bus_ctrl_vif", vif)) begin
      // if the interface was not correctly set, raise a fatal message
      `uvm_fatal("Driver", "No virtual interface specified for this test instance");
    end
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    bus_transaction transaction;

    DUT_reset();  // Power on Reset
  
    forever begin
      zero_sigs();
      seq_item_port.get_next_item(currTransaction);
      
      
      
      
      seq_item_port.item_done();
    end
  endtask

  task DUT_reset();
    `uvm_info(this.get_name(), "Resetting DUT", UVM_LOW);

    zero_sigs();

    @(posedge vif.clk);
    vif.nRST = '0;
    @(posedge vif.clk);
    vif.nRST = '1;
    @(posedge vif.clk);
    @(posedge vif.clk);
  endtask

  task zero_sigs();
    vif.dREN    = '0;
    vif.dWEN    = '0;
    vif.daddr   = '0;
    vif.dstore  = '0;
    vif.cctrans = '0;
    vif.ccwrite = '0;
    vif.ccsnoophit = '0;
    vif.ccIsPresent = '0;
    vif.ccdirty   = '0;
    vif.ccsnoopdone = '0;
  endtask

endclass : bus_driver

`endif
