/*
*   Copyright 2021 Purdue University
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
*   Filename:     tb_l1_cache.sv
*
*   Created by:   Rufat Imanov, Raviteja Vajja
*   Email:        rimanov@purdue.edu, rvajja@purdue.edu
*   Date Created: 07/18/2021
*   Description:  Testbench for parametrizable L1 Cache.
*/

`timescale 1ns / 10ps
`include "generic_bus_if.vh"

parameter CLK_PERIOD = 10;

module tb_l1_cache.sv
();

	// DUT Portmap Signals
	logic tb_CLK;
	logic tb_nRST;
	logic tb_clear;
	logic tb_flush;
	logic tb_clear_done;
	logic tb_flush_done;
	generic_bus_if.cpu tb_mem_gen_bus_if;
	generic_bus_if.generic_bus tb_proc_gen_bus_if;

	// Testbench Signals
	integer test_number;
	string test_case;
	logic test_checking;
	logic test_clear_done_expected;
	logic test_clear_done_mismatch;
	logic test_flush_done_expected;
	logic test_flush_done_mismatch;
	generic_bus_if.cpu test_mem_gen_bus_if_expected;
	generic_bus_if.cpu test_mem_gen_bus_if_mismatch;
	generic_bus_if.generic_bus test_proc_gen_bus_if_expected;
	generic_bus_if.generic_bus test_proc_gen_bus_if_mismatch;

	// Task to Reset DUT
	task reset_dut;
	begin

	tb_nRST = 1'b0;

	@(posedge tb_CLK);
	@(posedge tb_CLK);

	@(negedge tb_CLK);
	tb_nRST = 1'b1;

	@(negedge tb_CLK);
	@(negedge tb_CLK);

	end
	endtask

	// Task to Check Output
	task check_output;
	begin
		// TODO: add checks and prints
	end
	endtask

	// TODO: finish the testbench

endmodule
