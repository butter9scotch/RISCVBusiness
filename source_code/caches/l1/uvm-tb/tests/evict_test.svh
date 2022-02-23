// `ifndef EVICT_TEST_SVH
// `define EVICT_TEST_SVH

// import uvm_pkg::*;
// `include "basic_test.svh"
// `include "uvm_macros.svh"

// class evict_test extends basic_test;
//   `uvm_component_utils(evict_test)

//   evict_sequence seq;

//   function new(string name = "EVICT_TEST", uvm_component parent);
// 		super.new(name, parent);
// 	endfunction: new

//   function void build_phase(uvm_phase phase);
//     super.build_phase(phase);
//     seq = evict_sequence::type_id::create("EVICT_SEQ");
//   endfunction: build_phase

//   task run_phase(uvm_phase phase);
//     phase.raise_objection( this, "Starting sequence in main phase" );
//  		seq.start(env.cpu_agt.sqr);
// 		#100ns;
// 		phase.drop_objection( this , "Finished in main phase" );
//   endtask

// endclass: evict_test

// `endif