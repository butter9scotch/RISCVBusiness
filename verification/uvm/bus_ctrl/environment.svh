`ifndef ENVIROMENT_SVH
`define ENVIROMENT_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "bus_agent.svh"
`include "bus_ctrl_if.sv"
`include "bus_scoreboard.svh"  // uvm_scoreboard
`include "bus_predictor.svh"  // uvm_subscriber
`include "bus_transaction_v2.svh"  // uvm_sequence_item

class environment extends uvm_env;
  `uvm_component_utils(environment)

  bus_agent bus_agent;  // contains monitor and driver
  //bus_predictor bus_predictor;  // a reference model to check the result
  //bus_scoreboard bus_scoreboard;  // scoreboard

  function new(string name = "env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    // instantiate all the components through factory method
    bus_agent = bus_agent::type_id::create("bus_agent", this);
    //bus_predictor = bus_predictor::type_id::create("bus_predictor", this);
    //bus_scoreboard = bus_scoreboard::type_id::create("bus_scoreboard", this);
  endfunction


  // TODO: Connect everything up correctly
  function void connect_phase(uvm_phase phase);
    //bus_agent.ahb_mon.ahb_bus_ap.connect();  // connect monitor to predictor
    //bus_predictor.pred_ap.connect();  // connect predictor to comparator
    //bus_agent.ahb_mon.result_ap.connect();  // connect monitor to comparator
  endfunction

endclass : environment

`endif
