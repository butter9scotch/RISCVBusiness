`ifndef EVICT_TEST_SVH
`define EVICT_TEST_SVH

import uvm_pkg::*;
`include "base_test.svh"
`include "uvm_macros.svh"

class evict_test extends base_test#(evict_sequence, "EVICT_SEQ");
  `uvm_component_utils(evict_test)

  function new(string name = "", uvm_component parent);
		super.new(name, parent);
	endfunction: new

endclass: evict_test

`endif