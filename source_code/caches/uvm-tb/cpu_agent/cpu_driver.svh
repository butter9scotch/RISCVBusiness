/*
*   Copyright 2022 Purdue University
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*       http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*
*
*   Filename:     cpu_driver.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  UVM Driver class for initiating processor side requests to caches
*/

`ifndef CPU_DRIVER_SVH
`define CPU_DRIVER_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;
 
`include "uvm_macros.svh"

`include "generic_bus_if.vh"
`include "cache_if.svh"

class cpu_driver extends uvm_driver#(cpu_transaction);
  `uvm_component_utils(cpu_driver)

  virtual cache_if cif;
  virtual generic_bus_if cpu_bus_if;

  function new(string name, uvm_component parent);
		super.new(name, parent);
	endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if( !uvm_config_db#(virtual cache_if)::get(this, "", "cif", cif) ) begin
      `uvm_fatal($sformatf("%s/cif", this.get_name()), "No virtual interface specified for this test instance");
		end
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "cpu_bus_if", cpu_bus_if) ) begin
      `uvm_fatal($sformatf("%s/bus_if", this.get_name()), "No virtual interface specified for this test instance");
		end
    `uvm_info(this.get_name(), "pulled <cpu_if> and <cpu_bus_if> from db", UVM_HIGH)
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    cpu_transaction req_item;

    DUT_reset();

    forever begin 
      seq_item_port.get_next_item(req_item);
      `uvm_info(this.get_name(), $sformatf("Received new sequence item:\n%s", req_item.sprint()), UVM_HIGH)

      cpu_bus_if.addr = req_item.addr;
      cpu_bus_if.wdata = req_item.data;
      cpu_bus_if.ren = ~req_item.rw;  // read = 0
      cpu_bus_if.wen = req_item.rw;   // write = 1

      cpu_bus_if.byte_en = req_item.byte_sel; 
      //FIXME: NEED TO ADD CLEAR/FLUSH FUNCTIONALITY
      cif.clear = '0; 
      cif.flush = '0;

      do begin
        @(posedge cif.CLK);  //wait for memory to return
      end while (cpu_bus_if.busy == 1'b1);
      
      seq_item_port.item_done();
    end
  endtask: run_phase

  task DUT_reset();
    @(posedge cif.CLK);
    cif.nRST = 1;
    cif.clear = 0;
    cif.flush = 0;
    @(posedge cif.CLK);
    cif.nRST = 0;
    @(posedge cif.CLK);
    cif.nRST = 1;
    @(posedge cif.CLK);
  endtask

endclass: cpu_driver

`endif