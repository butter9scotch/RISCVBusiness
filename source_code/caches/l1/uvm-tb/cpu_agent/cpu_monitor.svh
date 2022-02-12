import uvm_pkg::*;
`include "uvm_macros.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class cpu_monitor extends uvm_monitor;
  `uvm_component_utils(cpu_monitor)

  virtual l1_cache_wrapper_if cif;
  virtual generic_bus_if cpu_bus_if;

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
    // get interface from database
    if( !uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cif", cif) ) begin
      `uvm_fatal("CPU Monitor/cif", "No virtual interface specified for this test instance");
		end
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "cpu_bus_if", cpu_bus_if) ) begin
      `uvm_fatal("CPU Monitor/cpu_bus_if", "No virtual interface specified for this test instance");
		end
  endfunction: build_phase

  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);

    forever begin
      cpu_transaction tx;
      @(posedge cpu_bus_if.ren, posedge cpu_bus_if.wen);
      // captures activity between the driver and DUT
      tx = cpu_transaction::type_id::create("tx");

      tx.addr = cpu_bus_if.addr;


      if (cpu_bus_if.ren) begin
        tx.rw = '0; // 0 -> read; 1 -> write
        tx.data = 32'hBAD0BAD0; //fill with garbage data
      end else if (cpu_bus_if.wen) begin
        tx.rw = '1; // 0 -> read; 1 -> write
        tx.data = cpu_bus_if.wdata;
      end
      `uvm_info("CPU MONITOR", $sformatf("\nNew Transaction Detected:\n%s", tx.sprint()), UVM_LOW)
      req_ap.write(tx);

      while (cpu_bus_if.busy) begin
        @(posedge cif.CLK);  //wait for memory to return
      end

      if (cpu_bus_if.ren) begin
        tx.data = cpu_bus_if.rdata;
      end

      resp_ap.write(tx);
    end
  endtask: run_phase

endclass: cpu_monitor
