`ifndef CPU_PREDICTOR_SHV
`define CPU_PREDICTOR_SHV

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "bus_predictor.svh"
`include "uvm_macros.svh"
`include "cpu_transaction.svh"

class cpu_predictor extends bus_predictor;
  `uvm_component_utils(cpu_predictor) 

  //TODO: REMOVE THIS CLASS IF NO EXTRA FEATURE IS BEING ADDED FROM BUS_PREDICTOR

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

endclass: cpu_predictor

`endif