`ifndef RAW_TEST_SVH
`define RAW_TEST_SVH

import uvm_pkg::*;
`include "base_test.svh"
`include "uvm_macros.svh"

class raw_test extends base_test#(raw_sequence, "RAW_SEQ");
  `uvm_component_utils(raw_test)

  function new(string name = "", uvm_component parent);
		super.new(name, parent);
	endfunction: new

endclass: raw_test

`endif