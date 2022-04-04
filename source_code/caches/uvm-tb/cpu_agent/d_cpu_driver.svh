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
*   Filename:     d_cpu_driver.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 04/04/2022
*   Description:  UVM Driver class for initiating processor side requests to data cache
*/

`ifndef D_CPU_DRIVER_SVH
`define D_CPU_DRIVER_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;
 
`include "uvm_macros.svh"

`include "generic_bus_if.vh"
`include "cache_if.svh"
`include "cpu_driver.svh"

class d_cpu_driver extends cpu_driver;
  `uvm_component_utils(d_cpu_driver)

  function new(string name, uvm_component parent);
		super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if( !uvm_config_db#(virtual cache_if)::get(this, "", "d_cif", cif) ) begin
      `uvm_fatal($sformatf("%s/d_cif", this.get_name()), "No virtual interface specified for this test instance");
		end
    `uvm_info(this.get_name(), "pulled <d_cif> from db", UVM_FULL)
    
    if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "d_cpu_bus_if", cpu_bus_if) ) begin
      `uvm_fatal($sformatf("%s/bus_if", this.get_name()), "No virtual interface specified for this test instance");
		end
    `uvm_info(this.get_name(), "pulled <d_cpu_bus_if> from db", UVM_FULL)
  endfunction: build_phase

endclass: d_cpu_driver

`endif