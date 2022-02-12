import uvm_pkg::*;
`include "uvm_macros.svh"
`include "cache_env.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class basic extends uvm_test;
  `uvm_component_utils(basic)

  cache_env env;
  virtual l1_cache_wrapper_if cif;
  virtual generic_bus_if cpu_bus_if;
  virtual generic_bus_if l1_bus_if;  
  basic_sequence seq;

  function new(string name = "basic", uvm_component parent);
		super.new(name, parent);
	endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
		env = cache_env::type_id::create("env",this);
    seq = basic_sequence::type_id::create("seq");

    // send the interface down
    if (!uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cif", cif)) begin 
      // check if interface is correctly set in testbench top level
		   `uvm_fatal("Basic/cif", "No virtual interface specified for this test instance")
		end 
    if (!uvm_config_db#(virtual generic_bus_if)::get(this, "", "cpu_bus_if", cpu_bus_if)) begin 
      // check if interface is correctly set in testbench top level
		   `uvm_fatal("Basic/cpu_bus_if", "No virtual interface specified for this test instance")
		end 
    if (!uvm_config_db#(virtual generic_bus_if)::get(this, "", "l1_bus_if", l1_bus_if)) begin 
      // check if interface is correctly set in testbench top level
		   `uvm_fatal("Basic/l1_bus_if", "No virtual interface specified for this test instance")
		end 

		uvm_config_db#(virtual l1_cache_wrapper_if)::set(this, "env.agt*", "cif", cif);
		uvm_config_db#(virtual generic_bus_if)::set(this, "env.agt*", "cpu_bus_if", cpu_bus_if);
		uvm_config_db#(virtual generic_bus_if)::set(this, "env.agt*", "l1_bus_if", l1_bus_if);

  endfunction: build_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection( this, "Starting sequence in main phase" );
 		seq.start(env.cpu_agt.sqr);
		#100ns;
		phase.drop_objection( this , "Finished in main phase" );
  endtask

endclass: basic
