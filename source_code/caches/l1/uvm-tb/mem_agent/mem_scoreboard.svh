`ifndef MEM_SCOREBOARD_SVH
`define MEM_SCOREBOARD_SVH

import uvm_pkg::*;
`include "bus_scoreboard.svh"
`include "uvm_macros.svh"

class mem_scoreboard extends bus_scoreboard;
  `uvm_component_utils(mem_scoreboard)

  //TODO: REMOVE THIS CLASS IF NO EXTRA FEATURE IS BEING ADDED FROM BUS_SCOREBOARD

  function new( string name , uvm_component parent) ;
		super.new( name , parent );
  endfunction: new

endclass : mem_scoreboard

`endif