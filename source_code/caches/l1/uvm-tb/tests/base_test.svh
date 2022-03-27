/*
*   Copyright 2022 Purdue University
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*       http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*
*
*   Filename:     base_test.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  UVM Test with default settings/configurations
*/

`ifndef BASE_TEST_SVH
`define BASE_TEST_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "cache_env.svh"
`include "cache_env_config.svh"

`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

class base_test#(type sequence_type = nominal_sequence, string sequence_name = "BASE_TEST") extends uvm_test;
  `uvm_component_utils(base_test)

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
    if ( !env_config.randomize()) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end
    
	  env = cache_env::type_id::create("ENV",this);
    env.env_config = env_config;

    seq = sequence_type::type_id::create(sequence_name);

    // send the interface down
    if (!uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cpu_cif", cpu_cif)) begin 
      // check if interface is correctly set in testbench top level
	    `uvm_fatal("Base/cif", "No virtual interface specified for this test instance")
	  end 
    if (!uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "mem_cif", mem_cif)) begin 
      // check if interface is correctly set in testbench top level
	    `uvm_fatal("Base/cif", "No virtual interface specified for this test instance")
	  end 
    if (!uvm_config_db#(virtual generic_bus_if)::get(this, "", "cpu_bus_if", cpu_bus_if)) begin 
      // check if interface is correctly set in testbench top level
		  `uvm_fatal("Base/cpu_bus_if", "No virtual interface specified for this test instance")
	  end 
    if (!uvm_config_db#(virtual generic_bus_if)::get(this, "", "l1_bus_if", l1_bus_if)) begin 
      // check if interface is correctly set in testbench top level
		  `uvm_fatal("Base/l1_bus_if", "No virtual interface specified for this test instance")
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
    if(!seq.randomize() with {
        N inside {[10:20]};
      }) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end

 		seq.start(env.cpu_agt.sqr);
		#100ns;
		phase.drop_objection( this , $sformatf("Finished <%s> in main phase", sequence_name) );
  endtask

endclass: base_test

`endif