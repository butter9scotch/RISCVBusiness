`ifndef MEM_PREDICTOR_SHV
`define MEM_PREDICTOR_SHV

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "bus_predictor.svh"
`include "uvm_macros.svh"
`include "cpu_transaction.svh"

class mem_predictor extends bus_predictor;
  `uvm_component_utils(mem_predictor) 

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  //override read functionality of bus_predictor
  function word_t read_mem(word_t addr);
    `uvm_info(this.get_name(), "Using Mem Predictor read_mem()", UVM_HIGH)

    if (this.memory.exists(addr)) begin
      return this.memory[addr];
    end else begin
      word_t default_val = 32'hbad9_bad9;
      `uvm_info(this.get_name(), $sformatf("Reading from Non-Initialized Memory, Defaulting to value <%h>", default_val), UVM_MEDIUM)
      return default_val; //TODO: CHANGE THIS TO CONFIGURABLE/RANDOMIZED PARAM
    end

  endfunction: read_mem

endclass: mem_predictor

`endif