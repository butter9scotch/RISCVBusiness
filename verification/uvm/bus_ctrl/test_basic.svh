import uvm_pkg::*;
`include "uvm_macros.svh"
`include "environment.svh"
`include "bus_ctrl_if.vh"

class test_basic extends uvm_test;
  `uvm_component_utils(test_basic)

  environment env;
  virtual bus_ctrl_if bus_ctrl_if;
  basic_sequence basicSeq;

  function new(string name = "test", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = environment::type_id::create("env", this);
    basicSeq = basic_sequence::type_id::create("basicSeq");


    // send the interface down
    if (!uvm_config_db#(virtual bus_ctrl_if)::get(this, "", "bus_ctrl_vip", bus_ctrl_if)) begin
      // check if interface is correctly set in testbench top level
      `uvm_fatal("TEST", "No virtual interface specified for this test instance")
    end

    uvm_config_db#(virtual bus_ctrl_if)::set(this, "env.agt*", "bus_ctrl_vif", bus_ctrl_if);

  endfunction : build_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this, "Starting basic non seq sequence in main phase");
    `uvm_info(this.get_name(), "Starting basic sequence....", UVM_LOW);
    basicSeq.start(env.bus_agent_agent.sqr);
    `uvm_info(this.get_name(), "Finished basic sequence", UVM_LOW);
    #100ns;
  endtask
endclass : test_basic
