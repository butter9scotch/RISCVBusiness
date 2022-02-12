`ifndef MEM_PREDICTOR_SHV
`define MEM_PREDICTOR_SHV

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "bus_predictor.svh"
`include "uvm_macros.svh"
`include "cpu_transaction.svh"

class mem_predictor extends bus_predictor;
  `uvm_component_utils(mem_predictor) 

  //TODO: REMOVE THIS CLASS IF NO EXTRA FEATURE IS BEING ADDED FROM BUS_PREDICTOR

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

endclass: mem_predictor

`endif