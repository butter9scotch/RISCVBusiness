`ifndef CPU_DRIVER_SVH
`define CPU_DRIVER_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;
 
`include "uvm_macros.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class cpu_driver extends uvm_driver#(cpu_transaction);
  `uvm_component_utils(cpu_driver)

  virtual l1_cache_wrapper_if cif;
  virtual generic_bus_if cpu_bus_if;

  function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if( !uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cpu_cif", cif) ) begin
      `uvm_fatal($sformatf("%s/cif", this.get_name()), "No virtual interface specified for this test instance");
		end
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "cpu_bus_if", cpu_bus_if) ) begin
      `uvm_fatal($sformatf("%s/bus_if", this.get_name()), "No virtual interface specified for this test instance");
		end
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    cpu_transaction req_item;

    DUT_reset();

    forever begin 
      seq_item_port.get_next_item(req_item);
      cpu_bus_if.addr = req_item.addr;
      cpu_bus_if.wdata = req_item.data;
      cpu_bus_if.ren = ~req_item.rw;  // read = 0
      cpu_bus_if.wen = req_item.rw;   // write = 1

      //FIXME: NEED TO ADD BYTE ENABLE FUNCTIONALITY
      cpu_bus_if.byte_en = 4'b1000; 
      //FIXME: NEED TO ADD CLEAR/FLUSH FUNCTIONALITY
      cif.clear = '0; 
      cif.flush = '0;

      while (cpu_bus_if.busy == 1'b1) begin
        @(posedge cif.CLK);  //wait for memory to return
      end
      
      @(posedge cif.CLK);
      seq_item_port.item_done();
    end
  endtask: run_phase

  task DUT_reset();
    @(posedge cif.CLK);
    cif.nRST = 1;
    cif.clear = 0;
    cif.flush = 0;
    @(posedge cif.CLK);
    cif.nRST = 0;
    @(posedge cif.CLK);
    cif.nRST = 1;
    @(posedge cif.CLK);
  endtask

endclass: cpu_driver

`endif