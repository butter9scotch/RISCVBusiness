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
*   Filename:     cache_env.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  UVM Environment for cache verification
*/

`ifndef CACHE_ENV_SVH
`define CACHE_ENV_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

`include "cache_env_config.svh" // config
`include "memory_bfm.svh" // bfm

`include "bus_predictor.svh" // uvm_subscriber
`include "bus_scoreboard.svh" // uvm_scoreboard

`include "d_cpu_agent.svh"
`include "i_cpu_agent.svh"
`include "cpu_transaction.svh" // uvm_sequence_item

`include "mem_agent.svh"
`include "l2_agent.svh"

`include "end2end.svh" // uvm_scoreboard

class cache_env extends uvm_env;
  `uvm_component_utils(cache_env)

  cache_env_config env_config; //environment configuration
  memory_bfm mem_bfm; //memory bus functional model
  
  d_cpu_agent d_cpu_agt; // contains monitor and driver
  bus_predictor d_cpu_pred; // a reference model to check the result
  bus_scoreboard d_cpu_score; // scoreboard

  i_cpu_agent i_cpu_agt; // contains monitor and driver
  bus_predictor i_cpu_pred; // a reference model to check the result
  bus_scoreboard i_cpu_score; // scoreboard

  l2_agent l2_agt; // contains monitor
  bus_predictor l2_pred; // a reference model to check the result
  bus_scoreboard l2_score; // scoreboard

  mem_agent mem_agt; // contains monitor
  bus_predictor mem_pred; // a reference model to check the result
  bus_scoreboard mem_score; // scoreboard


  end2end dl1_l2_e2e; //end to end checker from data l1 cache to l2 cache
  end2end il1_l2_e2e; //end to end checker from instr l1 cache to l2 cache

  function new(string name = "env", uvm_component parent = null);
		super.new(name, parent);
	endfunction

  function void build_phase(uvm_phase phase);
    d_cpu_agt = d_cpu_agent::type_id::create("D_CPU_AGT", this);
    d_cpu_pred = bus_predictor::type_id::create("D_CPU_PRED", this);
    d_cpu_score = bus_scoreboard::type_id::create("D_CPU_SCORE", this);

    i_cpu_agt = i_cpu_agent::type_id::create("I_CPU_AGT", this);
    i_cpu_pred = bus_predictor::type_id::create("I_CPU_PRED", this);
    i_cpu_score = bus_scoreboard::type_id::create("I_CPU_SCORE", this);

    l2_agt = l2_agent::type_id::create("L2_AGT", this);
    l2_pred = bus_predictor::type_id::create("L2_PRED", this);
    l2_score = bus_scoreboard::type_id::create("L2_SCORE", this);

    mem_agt = mem_agent::type_id::create("MEM_AGT", this);
    mem_pred = bus_predictor::type_id::create("MEM_PRED", this);
    mem_score = bus_scoreboard::type_id::create("MEM_SCORE", this);

    dl1_l2_e2e = end2end::type_id::create("DL1_L2_E2E", this);
    il1_l2_e2e = end2end::type_id::create("IL1_L2_E2E", this);

    mem_bfm = memory_bfm::type_id::create("MEM_BFM", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    // DATA L1 CACHE AGENT
    bus_connect(d_cpu_agt, d_cpu_pred, d_cpu_score);

    // INSTRUCTION L1 CACHE AGENT
    bus_connect(i_cpu_agt, i_cpu_pred, i_cpu_score);

    // MEMORY AGENT
    bus_connect(mem_agt, mem_pred, mem_score);

    // DATA L1 CACHE <-> L2 CACHE :: END TO END CHECKER
    d_cpu_agt.mon.req_ap.connect(dl1_l2_e2e.cpu_req_export);
    d_cpu_agt.mon.resp_ap.connect(dl1_l2_e2e.cpu_resp_export);
    l2_agt.mon.resp_ap.connect(dl1_l2_e2e.mem_resp_export);

    // INSTR L1 CACHE <-> L2 CACHE :: END TO END CHECKER
    i_cpu_agt.mon.req_ap.connect(il1_l2_e2e.cpu_req_export);
    i_cpu_agt.mon.resp_ap.connect(il1_l2_e2e.cpu_resp_export);
    l2_agt.mon.resp_ap.connect(il1_l2_e2e.mem_resp_export);
  endfunction


  function void bus_connect(bus_agent agt, bus_predictor pred, bus_scoreboard score);
    agt.mon.req_ap.connect(pred.analysis_export); // connect monitor to predictor 
    `uvm_info(this.get_name(), $sformatf("Connected <%s>-req_ap to <%s>", agt.mon.get_name(), pred.get_name()), UVM_FULL)

    pred.pred_ap.connect(score.expected_export); // connect predictor to scoreboard
    `uvm_info(this.get_name(), $sformatf("Connected <%s> to <%s>", pred.get_name(), score.get_name()), UVM_FULL)

    agt.mon.resp_ap.connect(score.actual_export); // connect monitor to scoreboard
    `uvm_info(this.get_name(), $sformatf("Connected <%s>-resp_ap to <%s>", agt.mon.get_name(), score.get_name()), UVM_FULL)
  endfunction: bus_connect

endclass: cache_env

`endif