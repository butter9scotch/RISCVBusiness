`ifndef BASIC_TEST_SVH
`define BASIC_TEST_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "cache_env.svh"
`include "cache_env_config.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

//TODO: CHANGE NAME TO BASE TEST
class basic_test#(type sequence_type = nominal_sequence, string sequence_name = "BASE_TEST") extends uvm_test;
  `uvm_component_utils(basic_test)

  sequence_type seq;

  cache_env_config env_config;
  cache_env env;
  virtual l1_cache_wrapper_if cpu_cif;
  virtual l1_cache_wrapper_if mem_cif;
  virtual generic_bus_if cpu_bus_if;
  virtual generic_bus_if l1_bus_if;  

  function new(string name = "", uvm_component parent);
		super.new(name, parent);
	endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env_config = cache_env_config::type_id::create("ENV_CONFIG", this);
    
	  env = cache_env::type_id::create("ENV",this);
    env.env_config = env_config;

    seq = sequence_type::type_id::create(sequence_name);

    // send the interface down
    if (!uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cpu_cif", cpu_cif)) begin 
      // check if interface is correctly set in testbench top level
	    `uvm_fatal("Basic/cif", "No virtual interface specified for this test instance")
	  end 
    if (!uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "mem_cif", mem_cif)) begin 
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

  //TODO: SHOULD I NARROW THE SCOPE OF THE ENV_CONFIG?
  uvm_config_db#(cache_env_config)::set(this, "*", "env_config", env_config);

	uvm_config_db#(virtual l1_cache_wrapper_if)::set(this, "env.agt*", "cpu_cif", cpu_cif);
	uvm_config_db#(virtual l1_cache_wrapper_if)::set(this, "env.agt*", "mem_cif", mem_cif);
	uvm_config_db#(virtual generic_bus_if)::set(this, "env.agt*", "cpu_bus_if", cpu_bus_if);
	uvm_config_db#(virtual generic_bus_if)::set(this, "env.agt*", "l1_bus_if", l1_bus_if);

  endfunction: build_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection( this, $sformatf("Starting <%s> in main phase", sequence_name) );
 		seq.start(env.cpu_agt.sqr);
		#100ns;
		phase.drop_objection( this , $sformatf("Finished <%s> in main phase", sequence_name) );
  endtask

endclass: basic_test

`endif