`ifndef INDEX_TEST_SVH
`define INDEX_TEST_SVH

import uvm_pkg::*;
`include "base_test.svh"
`include "uvm_macros.svh"
`include "index_sequence.svh"

class index_test extends base_test#(index_sequence, "INDEX_SEQ");
  `uvm_component_utils(index_test)

  function new(string name = "", uvm_component parent);
		super.new(name, parent);
	endfunction: new

endclass: index_test

`endif