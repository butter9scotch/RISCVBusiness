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
*   Filename:     cpu_agent.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  UVM Agent to stand in for the processor side of the caches
*/

`ifndef CPU_AGENT_SVH
`define CPU_AGENT_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "nominal_sequence.svh"
`include "index_sequence.svh"
`include "evict_sequence.svh"
`include "mmio_sequence.svh"
`include "cpu_driver.svh"
`include "cpu_monitor.svh"

typedef uvm_sequencer#(cpu_transaction) cpu_sequencer;

class cpu_agent extends uvm_agent;
  `uvm_component_utils(cpu_agent)
  cpu_sequencer sqr;
  cpu_driver drv;
  cpu_monitor mon;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);   
    sqr = cpu_sequencer::type_id::create("CPU_SQR", this);
    drv = cpu_driver::type_id::create("CPU_DRV", this);
    mon = cpu_monitor::type_id::create("CPU_MON", this);
    `uvm_info(this.get_name(), $sformatf("Created <%s>, <%s>, <%s>", drv.get_name(), sqr.get_name(), mon.get_name()), UVM_FULL)
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
    `uvm_info(this.get_name(), $sformatf("Connected <%s> to <%s>", drv.get_name(), sqr.get_name()), UVM_FULL)
  endfunction

endclass: cpu_agent

`endif