// `ifndef RAW_TEST_SVH
// `define RAW_TEST_SVH

// import uvm_pkg::*;
// `include "basic_test.svh"
// `include "uvm_macros.svh"

// class raw_test extends basic_test;
//   `uvm_component_utils(raw_test)

//   raw_sequence seq;

//   function new(string name = "RAW_TEST", uvm_component parent);
// 		super.new(name, parent);
// 	endfunction: new

//   function void build_phase(uvm_phase phase);
//     super.build_phase(phase);
//     seq = raw_sequence::type_id::create("RAW_SEQ");
//   endfunction: build_phase

//   task run_phase(uvm_phase phase);
//     phase.raise_objection( this, "Starting sequence in main phase" );
//  		seq.start(env.cpu_agt.sqr);
// 		#100ns;
// 		phase.drop_objection( this , "Finished in main phase" );
//   endtask

// endclass: raw_test

// `endif