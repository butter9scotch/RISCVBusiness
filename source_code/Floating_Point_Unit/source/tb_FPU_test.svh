import uvm_pkg::*;
`include "uvm_macros.svh"

`include "tb_FPU_sequencer.svh"
`include "tb_FPU_env.svh"


class FPU_test extends uvm_test;
  `uvm_component_utils(FPU_test)

  FPU_env env;
  virtual FPU_if vif;
  FPU_sequence seq;

  function new(string name = "FPU_test", uvm_component parent);
		super.new(name, parent);
	endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
		env = FPU_env::type_id::create("env",this);
    seq = FPU_sequence::type_id::create("seq");

    // send the interface down
    if (!uvm_config_db#(virtual FPU_if)::get(this, "", "vif", vif)) begin
		   `uvm_fatal("TEST", "No virtual interface specified for this test instance")
		end 

		uvm_config_db#(virtual FPU_if)::set(this, "env.agt*", "vif", vif);

  endfunction: build_phase
  
  task run_phase(uvm_phase phase);
    phase.raise_objection( this, "Starting apb_base_seq in main phase" );
		$display("%t Starting sequence FPU_seq run_phase",$time);
 		seq.start(env.FPU_agt.sqr);
		#100ns;
		phase.drop_objection( this , "Finished apb_seq in main phase" );
  endtask

endclass //FPU_test