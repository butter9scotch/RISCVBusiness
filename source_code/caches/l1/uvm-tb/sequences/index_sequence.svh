`ifndef INDEX_SEQUENCE_SVH
`define INDEX_SEQUENCE_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "cpu_transaction.svh"

`include "dut_params.svh"

/** Sequence to test read after writes to the same location */
class index_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(index_sequence)

  rand int N; //number of iterations of eviction events

  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    cpu_transaction req_item;
    int N_reps; // used to back calculate proper repetitions to used when combined with inner for loop

    logic [`ADDR_IDX_SIZE-1:0] index;
    word_t block_words[word_t];

    req_item = cpu_transaction::type_id::create("req_item");

    N_reps = N / (`L1_BLOCK_SIZE);

    `uvm_info(this.get_name(), $sformatf("Requested size: %0d; Creating sequence with size N=%0d", N, N_reps * (`L1_BLOCK_SIZE)), UVM_LOW)
    
    repeat(N_reps) begin
      for (int i = 0; i < `L1_BLOCK_SIZE; i++) begin
        start_item(req_item);
        if(!req_item.randomize() with {
          if (i != 0) {
            // first iteration is completely random txn
            addr[31:`ADDR_IDX_END] == index;
            addr inside {block_words};        
          }
          }) begin
          `uvm_fatal("Randomize Error", "not able to randomize")
        end
        index = req_item.addr[31:`ADDR_IDX_END];

        if (i == 0) begin
          // initialize block words arrays
          for (int j = 0; j < `L1_BLOCK_SIZE*4; j+=4) begin
            word_t temp = {index, j[`ADDR_IDX_END-1:0]};
            block_words[temp] = temp;
          end
        end

        block_words.delete(req_item.addr); // remove from list of addresses to r/w

        `uvm_info(this.get_name(), $sformatf("Generated New Sequence Item:\n%s", req_item.sprint()), UVM_HIGH)

        finish_item(req_item);
      end
    end
  endtask: body
endclass: index_sequence

`endif