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

  task run_phase(uvm_phase phase);
    phase.raise_objection( this, $sformatf("Starting <%s> in main phase", sequence_name) );
    if(!seq.randomize() with {
      N inside {[10:20]};
    }) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end

 		seq.start(env.cpu_agt.sqr);
		#100ns;
		phase.drop_objection( this , $sformatf("Finished <%s> in main phase", sequence_name) );
  endtask

endclass: nominal_test

`endif


