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
*   Filename:     end2end.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  UVM Component for ensuring proper translation between processor and memory side of the caches
*/

`ifndef END2END_SVH
`define END2END_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"
`include "dut_params.svh"
`include "cpu_transaction.svh"
`include "cache_model.svh"
`include "Utils.svh"

`uvm_analysis_imp_decl(_cpu_req)
`uvm_analysis_imp_decl(_cpu_resp)
`uvm_analysis_imp_decl(_mem_resp)

class end2end extends uvm_component;
  `uvm_component_utils(end2end) 

  uvm_analysis_imp_cpu_req #(cpu_transaction, end2end) cpu_req_export;
  uvm_analysis_imp_cpu_resp #(cpu_transaction, end2end) cpu_resp_export;
  uvm_analysis_imp_mem_resp #(cpu_transaction, end2end) mem_resp_export;

  cache_model cache; // holds values currently stored in cache

  cpu_transaction history[$]; // holds recent mem bus transactions

  int successes, errors; // records number of matches and mismatches

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    cpu_req_export = new("cpu_req_ap", this);
    cpu_resp_export = new("cpu_resp_ap", this);
    mem_resp_export = new("mem_resp_ap", this);
    cache = new("e2e_cache");
  endfunction: new

  function void write_cpu_req(cpu_transaction t);
    cpu_transaction tx = cpu_transaction::type_id::create("cpu_req_tx", this);
    tx.copy(t);

    `uvm_info(this.get_name(), $sformatf("Detected CPU Request @%h", tx.addr), UVM_MEDIUM);

    if (history.size() > 0) begin
      flush_history();
    end
  endfunction: write_cpu_req

  function void write_cpu_resp(cpu_transaction t);
    cpu_transaction tx = cpu_transaction::type_id::create("cpu_resp_tx", this);
    tx.copy(t);

    `uvm_info(this.get_name(), $sformatf("Detected CPU Response @%h", tx.addr), UVM_MEDIUM);

    if (tx.addr < `NONCACHE_START_ADDR) begin
      // memory request
      if (history.size() == 0) begin
        // quiet memory bus

        if (cache.exists(tx.addr)) begin
          // data is cached
          successes++;
          `uvm_info(this.get_name(), "Success: Cache Hit -> Quiet Mem Bus", UVM_LOW);
        end else begin
          // data not in cache
          errors++;
          `uvm_error(this.get_name(), "Error: Cache Miss -> Quiet Mem Bus");
        end
      end else begin
        // active memory bus
        if (cache.exists(tx.addr)) begin
          // data is already cached
          errors++;
          `uvm_error(this.get_name(), "Error: Cache Hit -> Active Mem Bus");
        end else begin
          // data not in cache, need to get data from memory

        flush_history();

        if (cache.exists(tx.addr)) begin
          successes++;
          `uvm_info(this.get_name(), "Success: Cache Miss -> Active Mem Bus", UVM_LOW);
        end else begin
          errors++;
          `uvm_error(this.get_name(), "Error: Data Requested by CPU is not pressent in cache after mem bus txns");
        end
      end 
    end

    if (tx.rw) begin
      // update cache on PrWr
      cache.update(tx.addr, tx.data);
    end
  end else begin
      // memory mapped io request

      if (history.size() == 1) begin
        cpu_transaction mapped = history.pop_front();
        //FIXME:CHECK THAT THIS IS PROPER WAY TO DEAL WITH THIS
        if (tx.rw) begin
          tx.data = Utils::byte_mask(tx.byte_sel) & tx.data;
        end
        if (mapped.compare(tx)) begin
          successes++;
          `uvm_info(this.get_name(), "Success: Mem Mapped I/O Pass Through Match", UVM_LOW);
        end else begin
          errors++;
          `uvm_error(this.get_name(), "Error: Mem Mapped I/O Pass Through Mismatch");
          `uvm_info(this.get_name(), $sformatf("\ncpu req:\n%s\nmem bus:\n%s",tx.sprint(), mapped.sprint()), UVM_LOW)
        end
      end else begin
        errors++;
        `uvm_error(this.get_name(), $sformatf("Error: Mem Mapped I/O Pass Through Transaction Size Mismatch: expected 1, actual %0d", history.size()));
      end
    end
  endfunction: write_cpu_resp

  function void write_mem_resp(cpu_transaction t);
    cpu_transaction tx = cpu_transaction::type_id::create("mem_resp_tx", this);
    tx.copy(t);

    `uvm_info(this.get_name(), $sformatf("Detected Memory Response:: addr=%h", tx.addr), UVM_MEDIUM);

    history.push_back(tx);
  endfunction: write_mem_resp

  function void report_phase(uvm_phase phase);
    `uvm_info(this.get_name(), $sformatf("Successes:    %0d", successes), UVM_LOW);
    `uvm_info(this.get_name(), $sformatf("Errors: %0d", errors), UVM_LOW);
  endfunction

  function void handle_mem_tx(cpu_transaction mem_tx);
    if (mem_tx.rw) begin
      // write
      // writes are cache evictions
      cache.remove(mem_tx.addr, mem_tx.data);
    end else begin
      // read
      cache.insert(mem_tx.addr, mem_tx.data);
    end
  endfunction: handle_mem_tx

  function void flush_history();
    int block_idx = 0;

    if (history.size() % `L1_BLOCK_SIZE != 0) begin
      errors++;
      `uvm_error(this.get_name(), $sformatf("memory word requests do not match block size: requested %0d, not evenly divisible by: %0d", history.size(), `L1_BLOCK_SIZE));
    end

    while (history.size() > 0) begin
      cpu_transaction t = history.pop_front();
      handle_mem_tx(t);
      block_idx++;
      if (block_idx % `L1_BLOCK_SIZE == 0) begin
        // last word of block
        if (cache.is_valid_block(t.addr)) begin
          successes++;
          `uvm_info(this.get_name(), $sformatf("Valid block read from memory: %h", t.addr), UVM_LOW);
        end else begin
          errors++;
          `uvm_error(this.get_name(), $sformatf("Invalid word addresses when fetching block from memory: %h", t.addr));
          `uvm_info(this.get_name(), $sformatf("%s", cache.sprint()), UVM_LOW);
        end
      end 
    end
  endfunction: flush_history

endclass: end2end

`endif