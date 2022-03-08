`ifndef MMIO_TEST_SVH
`define MMIO_TEST_SVH

import uvm_pkg::*;
`include "base_test.svh"
`include "mmio_sequence.svh"
`include "uvm_macros.svh"


class mmio_test extends base_test#(mmio_sequence, "MMIO_SEQ");
  `uvm_component_utils(mmio_test)

  function new(string name = "", uvm_component parent);
		super.new(name, parent);
	endfunction: new

endclass: mmio_test

`endif


