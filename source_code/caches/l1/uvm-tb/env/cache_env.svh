`ifndef CACHE_ENV_SVH
`define CACHE_ENV_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "cache_env_config.svh" // config

`include "cpu_agent.svh"
`include "cpu_scoreboard.svh" // uvm_scoreboard
`include "cpu_predictor.svh" // uvm_subscriber
`include "cpu_transaction.svh" // uvm_sequence_item

class cache_env extends uvm_env;
  `uvm_component_utils(cache_env)

  cache_env_config env_config; //environment configuration
  
  cpu_agent cpu_agt; // contains monitor and driver
  cpu_predictor pred; // a reference model to check the result
  cpu_scoreboard comp; // scoreboard

  function new(string name = "env", uvm_component parent = null);
		super.new(name, parent);
	endfunction

  function void build_phase(uvm_phase phase);
    // instantiate all the components through factory method
    cpu_agt = cpu_agent::type_id::create("cpu_agt", this);
    pred = cpu_predictor::type_id::create("pred", this);
    comp = cpu_scoreboard::type_id::create("comp", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    cpu_agt.mon.req_ap.connect(pred.analysis_export); // connect monitor to predictor
    pred.pred_ap.connect(comp.expected_export); // connect predictor to scoreboard
    cpu_agt.mon.resp_ap.connect(comp.actual_export); // connect monitor to scoreboard
  endfunction

endclass: cache_env

`endif