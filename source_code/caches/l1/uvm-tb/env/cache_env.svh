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
  cpu_predictor cpu_pred; // a reference model to check the result
  cpu_scoreboard cpu_score; // scoreboard

  function new(string name = "env", uvm_component parent = null);
		super.new(name, parent);
	endfunction

  function void build_phase(uvm_phase phase);
    // instantiate all the components through factory method
    cpu_agt = cpu_agent::type_id::create("CPU_AGT", this);
    cpu_pred = cpu_predictor::type_id::create("CPU_PRED", this);
    cpu_score = cpu_scoreboard::type_id::create("CPU_SCORE", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    cpu_agt.mon.req_ap.connect(cpu_pred.analysis_export); // connect monitor to predictor
    cpu_pred.pred_ap.connect(cpu_score.expected_export); // connect predictor to scoreboard
    cpu_agt.mon.resp_ap.connect(cpu_score.actual_export); // connect monitor to scoreboard

    //TODO: ADD CONNECT CPU AGENT TO END2END
    //TODO: ADD CONNECT MEM AGENT TO SCOREBOARD, PREDICTOR AND END2END
  endfunction

endclass: cache_env

`endif