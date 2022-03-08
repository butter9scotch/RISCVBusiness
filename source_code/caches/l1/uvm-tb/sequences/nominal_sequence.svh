`ifndef NOMINAL_SEQUENCE_SVH
`define NOMINAL_SEQUENCE_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "cpu_transaction.svh"

/** Sequence to test read after writes to the same location */
class nominal_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(nominal_sequence)
  function new(string name = "");
    super.new(name);
  endfunction: new

  rand int N;  // total number of processor side transactions

  constraint even {N%2==0;}

  task body();
    cpu_transaction req_item;
    int write_count; // current number of writes
    word_t writes[word_t]; // queue of write addresses

    req_item = cpu_transaction::type_id::create("req_item");

    write_count = 0;

    `uvm_info(this.get_name(), $sformatf("Creating sequence with size N=%0d", N), UVM_LOW)
    
    repeat(N) begin
      start_item(req_item);

      // writes.shuffle();
      if(!req_item.randomize() with {
        if (write_count >= N/2) {
          //only reads allowed
          rw == 0;
        }
        if (rw == 0) {
          //read from previously written addr
          addr inside {writes};
        }
        }) begin
        `uvm_fatal("Randomize Error", "not able to randomize")
      end

      if (req_item.rw) begin
        // write
        write_count++;
        writes[req_item.addr] = req_item.addr;
      end else begin
        // read
        writes.delete(req_item.addr);
      end

      `uvm_info(this.get_name(), $sformatf("Generated New Sequence Item:\n%s", req_item.sprint()), UVM_HIGH)

      finish_item(req_item);
    end
  endtask: body
endclass: nominal_sequence

`endif