`ifndef END2END_SVH
`define END2END_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"
`include "cpu_transaction.svh"
`include "cache_model.svh"

class end2end extends uvm_scoreboard;
  `uvm_component_utils(end2end) 

  uvm_analysis_export #(cpu_transaction) cpu_export;
  uvm_analysis_export #(cpu_transaction) mem_export;

  uvm_tlm_analysis_fifo #(cpu_transaction) cpu_fifo;
  uvm_tlm_analysis_fifo #(cpu_transaction) mem_fifo;

  cache_model cache; // holds values currently stored in cache

  int m_matches, m_mismatches; // records number of matches and mismatches

 
  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    cpu_export = new("cpu_export", this);
    mem_export = new("mem_export", this);

    cpu_fifo = new("cpu_fifo", this);
    mem_fifo = new("mem_fifo", this);

    cache = new("e2e_cache");
  endfunction

  function void connect_phase(uvm_phase phase);
    cpu_export.connect(cpu_fifo.analysis_export);
    mem_export.connect(mem_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    cpu_transaction prev_cpu_tx;
    cpu_transaction cpu_tx;
    cpu_transaction mem_tx;

    prev_cpu_tx = new();

    forever begin
      cpu_fifo.get(cpu_tx);
      `uvm_info(this.get_name(), $sformatf("Recieved new cpu value:\n%s", cpu_tx.sprint()), UVM_HIGH);

      if (!mem_fifo.is_empty()) begin
        // flush all transactions made on mem bus without a processor req (prefetch)
        mem_fifo.peek(mem_tx);
        while(mem_tx.cycle < prev_cpu_tx.cycle) begin
          mem_fifo.get(mem_tx);
          handle_mem_tx(mem_tx);
        end
      end
  
      if (mem_fifo.is_empty()) begin
        // quiet memory bus

        if (cache.exists(cpu_tx.addr)) begin
          // data is cached
          m_matches++;
          `uvm_info(this.get_name(), "Success: Cache Hit -> Quiet Mem Bus", UVM_LOW);
        end else begin
          // data not in cache
          m_mismatches++;
          `uvm_error(this.get_name(), "Error: Cache Miss -> Quiet Mem Bus");
        end
      end else begin
        // active memory bus

        if (cache.exists(cpu_tx.addr)) begin
          // data is already cached
          m_mismatches++;
          `uvm_error(this.get_name(), "Error: Cache Hit -> Active Mem Bus");
        end else begin
          // data not in cache, need to get data from memory

          // update cache from mem bus transactions
          while(!mem_fifo.is_empty()) begin
            mem_fifo.get(mem_tx);
            handle_mem_tx(mem_tx);
          end

          if (cache.exists(cpu_tx.addr)) begin
            m_matches++;
            `uvm_info(this.get_name(), "Success: Cache Miss -> Active Mem Bus", UVM_LOW);
          end else begin
            m_mismatches++;
            `uvm_error(this.get_name(), "Error: Data Requested by CPU is not pressent in cache after mem bus txns");
          end
        end   
      end

      if (cpu_tx.rw) begin
        // update cache on PrWr
        cache.update(cpu_tx.addr, cpu_tx.data);
      end

      prev_cpu_tx.copy(cpu_tx);
    end
  endtask

  function void report_phase(uvm_phase phase);
    `uvm_info(this.get_name(), $sformatf("Matches:    %0d", m_matches), UVM_LOW);
    `uvm_info(this.get_name(), $sformatf("Mismatches: %0d", m_mismatches), UVM_LOW);
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

endclass: end2end

`endif