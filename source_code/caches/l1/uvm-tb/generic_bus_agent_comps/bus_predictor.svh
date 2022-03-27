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
*   Filename:     bus_predictor.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  UVM subscriber class for predicting the operation of a generic_bus_if
*/


`ifndef BUS_PREDICTOR_SHV
`define BUS_PREDICTOR_SHV

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"
`include "cpu_transaction.svh"

class bus_predictor extends uvm_subscriber #(cpu_transaction);
  `uvm_component_utils(bus_predictor) 

  uvm_analysis_port #(cpu_transaction) pred_ap;
  cpu_transaction pred_tx;

  cache_env_config env_config;

  word_t memory [word_t]; //software cache

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    
    pred_ap = new("pred_ap", this);
    
    // get config from database
    if( !uvm_config_db#(cache_env_config)::get(this, "", "env_config", env_config) ) begin
      `uvm_fatal(this.get_name(), "env config not registered to db")
		end

  endfunction

  function void write(cpu_transaction t);
    string str;
    // t is the transaction sent from monitor
    pred_tx = cpu_transaction::type_id::create("pred_tx", this);
    pred_tx.copy(t);

    `uvm_info(this.get_name(), $sformatf("Recevied Transaction:\n%s", pred_tx.sprint()), UVM_HIGH)

    $swriteh(str,"memory before:\n%p",memory);
    `uvm_info(this.get_name(), str, UVM_HIGH)

    if (pred_tx.rw) begin
      // 1 -> write
      memory[pred_tx.addr] = pred_tx.data;
    end else begin
      // 0 -> read
      pred_tx.data = byte_mask(read_mem(pred_tx.addr), pred_tx.byte_sel);
    end

    $swriteh(str,"memory after:\n%p",memory);
    `uvm_info(this.get_name(), str, UVM_HIGH)

    // after prediction, the expected output send to the scoreboard 
    pred_ap.write(pred_tx);
  endfunction: write

  function word_t byte_mask(word_t data, logic [3:0] byte_sel);
    word_t mask;
    word_t ret;

    mask = 32'hff;
    ret = '0;
    for (int i = 0; i < 4; i++) begin
      if (byte_sel[i]) begin
        ret |= data & mask;
      end
      mask = mask << 8;
    end
    return ret;
  endfunction: byte_mask

  virtual function word_t read_mem(word_t addr);
    // `uvm_info(this.get_name(), "Using Bus Predictor read_mem()", UVM_FULL)
    if (addr < `NONCACHE_START_ADDR) begin
      // expect memory to return
      if (this.memory.exists(addr)) begin
        // block[addr] is already cached
        return this.memory[addr];
      end else begin
        word_t default_val = {env_config.mem_tag, addr[15:0]};
        `uvm_info(this.get_name(), $sformatf("Reading from Non-Initialized Memory, Defaulting to value <%h>", default_val), UVM_MEDIUM)
        return default_val; 
      end
    end else begin
      // expect mmio to respond
      word_t default_val = {env_config.mmio_tag, addr[15:0]};
      `uvm_info(this.get_name(), $sformatf("Reading from Memory Mapped Address Space, Defaulting to value <%h>", default_val), UVM_MEDIUM)
      return default_val;
    end
  endfunction: read_mem

endclass: bus_predictor

`endif