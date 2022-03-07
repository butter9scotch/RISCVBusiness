`ifndef RANDOM_TEST_SVH
`define RANDOM_TEST_SVH

import uvm_pkg::*;
`include "basic_test.svh"
`include "master_sequence.svh"
`include "uvm_macros.svh"

class random_test extends basic_test#(master_sequence, "MASTER_SEQ");
  `uvm_component_utils(random_test)

  function new(string name = "random_test", uvm_component parent);
		super.new(name, parent);
	endfunction: new

  task run_phase(uvm_phase phase);
    phase.raise_objection( this, $sformatf("Starting <%s> in main phase", this.get_name()) );

    if(!seq.randomize()) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end
  
 		seq.start(env.cpu_agt.sqr);
		#100ns;
		phase.drop_objection( this , $sformatf("Finished <%s> in main phase", this.get_name()) );
  endtask

endclass: random_test

`endif


