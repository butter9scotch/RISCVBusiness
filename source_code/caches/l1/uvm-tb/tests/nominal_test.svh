`ifndef NOMINAL_TEST_SVH
`define NOMINAL_TEST_SVH

import uvm_pkg::*;
`include "basic_test.svh"
`include "nominal_sequence.svh"
`include "uvm_macros.svh"

//TODO: TRY TO FIGURE OUT HOW TO MAKE THIS TYPEDEF WORK
// typedef basic_test#(nominal_sequence, "NOMINAL_SEQ") nominal_test;

class nominal_test extends basic_test#(nominal_sequence, "NOMINAL_SEQ");
  `uvm_component_utils(nominal_test)

  function new(string name = "", uvm_component parent);
		super.new(name, parent);
	endfunction: new

endclass: nominal_test

`endif


