`ifndef BUS_MONITOR_SVH
`define BUS_MONITOR_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class bus_monitor extends uvm_monitor;
  `uvm_component_utils(bus_monitor)

  virtual l1_cache_wrapper_if cif;
  virtual generic_bus_if bus_if;

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
    // NOTE: extended classes must get interfaces from db
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      cpu_transaction tx;
      @(posedge bus_if.ren, posedge bus_if.wen);
      // captures activity between the driver and DUT
      tx = cpu_transaction::type_id::create("tx");

      tx.addr = bus_if.addr;

      if (bus_if.ren) begin
        tx.rw = '0; // 0 -> read; 1 -> write
        tx.data = 32'hbad2_dada; //fill with garbage data
      end else if (bus_if.wen) begin
        tx.rw = '1; // 0 -> read; 1 -> write
        tx.data = bus_if.wdata;
      end
   
      `uvm_info(this.get_name(), $sformatf("Writing Req AP:\nReq Ap:\n%s", tx.sprint()), UVM_FULL)
      req_ap.write(tx);

      do begin
        @(posedge cif.CLK); //wait for memory to return
      end while (bus_if.busy);

      if (bus_if.ren) begin
        tx.data = bus_if.rdata;
      end

      `uvm_info(this.get_name(), $sformatf("Writing Resp AP:\nReq Ap:\n%s", tx.sprint()), UVM_FULL)
      resp_ap.write(tx);
    end
  endtask: run_phase

endclass: bus_monitor

`endif