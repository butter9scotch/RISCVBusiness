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

  int successes, errors; // records number of matches and mismatches

 
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
    int count; // count number of words read from memory for given txn

    prev_cpu_tx = new();

    prev_cpu_tx.cycle = 2147483647; // max integer value (infinity)

    forever begin
      cpu_fifo.get(cpu_tx);
      `uvm_info(this.get_name(), $sformatf("Recieved new cpu value:\n%s", cpu_tx.sprint()), UVM_HIGH);

      //TODO: THIS HASN'T BEEN TESTED FOR CORRECTNESS BECAUSE WE DON'T YET HAVE PREFETCHING
      flush_mem_txn(prev_cpu_tx.cycle); // flush all transactions made on mem bus without a processor req (prefetch)

      if (mem_fifo.is_empty()) begin
        // quiet memory bus

        if (cache.exists(cpu_tx.addr)) begin
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

        if (cache.exists(cpu_tx.addr)) begin
          // data is already cached
          errors++;
          `uvm_error(this.get_name(), "Error: Cache Hit -> Active Mem Bus");
        end else begin
          // data not in cache, need to get data from memory

          flush_mem_txn(0);

          if (cache.exists(cpu_tx.addr)) begin
            successes++;
            `uvm_info(this.get_name(), "Success: Cache Miss -> Active Mem Bus", UVM_LOW);
          end else begin
            errors++;
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

  task flush_mem_txn(int start_cycle);
    cpu_transaction mem_tx;
    if (!mem_fifo.is_empty()) begin
      int count = 0;
      // flush all transactions made on mem bus without a processor req (prefetch)
      mem_fifo.peek(mem_tx);
      // $display("start: %d, cur: %d", start_cycle, mem_tx.cycle);
      while(mem_tx.cycle > start_cycle) begin
        // $display("here");
        mem_fifo.get(mem_tx);
        // $display("start: %d, cur: %d", start_cycle, mem_tx.cycle);
        handle_mem_tx(mem_tx);
        count++;
        if (mem_fifo.is_empty()) begin
          break;
        end
      end

      if (count % `L1_BLOCK_SIZE != 0) begin
        errors++;
        `uvm_error(this.get_name(), $sformatf("memory word requests do not match block size: requested %0d, not evenly divisible by: %0d", count, `L1_BLOCK_SIZE));
      end
    end
  endtask: flush_mem_txn

endclass: end2end

`endif