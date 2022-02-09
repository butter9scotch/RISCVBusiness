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
    if( !uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cif", cif) ) begin
      `uvm_fatal("CPU_Driver/cif", "No virtual interface specified for this test instance");
		end
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "cpu_bus_if", cpu_bus_if) ) begin
      `uvm_fatal("CPU_Driver/cpu_bus_if", "No virtual interface specified for this test instance");
		end
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    //TODO: NEEDS IMPLEMENTATION
    cpu_transaction req_item;

    forever begin 
      seq_item_port.get_next_item(req_item);
      DUT_reset();
      cpu_bus_if.addr = req_item.addr;
      // cpu_buf_if.wdata = req_item.data; //FIXME: UNCOMMENTING THIS BREAKS BUILD
      cpu_bus_if.ren = ~req_item.rw;  // read = 0
      cpu_bus_if.wen = req_item.rw;   // write = 1

      //FIXME: NEED TO ADD BYTE ENABLE FUNCTIONALITY
      cpu_bus_if.byte_en = '1; //FIXME: DOES THIS MEAN ENABLE FULL WORD?

      //FIXME: NEED TO ADD CLEAR/FLUSH FUNCTIONALITY
      cif.clear = '0; 
      cif.flush = '0;
      
      @(negedge cpu_bus_if.busy);

      if (~req_item.rw) begin
        //read
        req_item.data = cpu_bus_if.rdata;
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
