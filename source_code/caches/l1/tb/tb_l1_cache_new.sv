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
	// Defined Constants
	localparam RAM_WIDTH = 32;
	localparam ADDR_WIDTH = 32;
	localparam CLK_PERIOD = 10;
	localparam PROPAGATION_DELAY = 3;

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
	typedef struct {
		logic clear_done_expected;
		logic clear_done_mismatch;
		logic flush_done_expected;
		logic flush_done_mismatch;
		logic [RAM_WIDTH-1:0] cpu_rdata;
		logic cpu_ren;
		logic [RAM_WIDTH-1:0] cpu_wdata;
		logic cpu_wen;
		logic cpu_busy;
		logic cpu_byte_en;
		logic [ADDR_WIDTH-1:0] cpu_waddr;
		logic [ADDR_WIDTH-1:0] cpu_raddr;
		logic [RAM_WIDTH-1:0] mem_rdata;
		logic mem_ren;
		logic [RAM_WIDTH-1:0] mem_wdata;
		logic mem_wen;
		logic mem_wen;
		logic mem_busy;
		logic mem_byte_en;
		logic [ADDR_WIDTH-1:0] mem_addr;
	} cache_test_t;
	cache_test_t inst_signals;
	cache_test_t data_signals;

	// Task to Reset DUTs
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


	// Task to emulate data write from CPU
	task cpu_write;
		input logic [RAM_WIDTH-1:0] data;
		input logic [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.cpu_wen = 1'b1;
		data_signals.cpu_wdata = data;
		data_signals.cpu_waddr = addr;

		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.cpu_wen = 1'b0;
		data_signals.cpu_wdata = '0;
		data_signals.cpu_waddr = '0;
		
	end
	endtask

	// Task to emulate data read from CPU
	task cpu_read;
		input logic [RAM_WIDTH-1:0] data;  // Not necessary, can be used for checks
		input logic [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.cpu_ren = 1'b1;
		data_signals.cpu_raddr = addr;

		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.cpu_ren = 1'b0;
		data_signals.cpu_raddr = '0;
		

		//TODO: some sort of checking?
	end
	endtask

	// Task to emulate fetch from memory
	task mem_fetch;
		input logic [RAM_WIDTH-1:0] data;  // Not necessary, can be used for checks
		input logic [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.mem_ren = 1'b1;
		data_signals.mem_raddr = addr;

		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.mem_ren = 1'b0;
		data_signals.mem_raddr = '0;

		//TODO: some sort of checking?
	end
	endtask

	// Task to emulate write back to memory
	task mem_write_back;
		input logic [RAM_WIDTH-1:0] data;
		input logic [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.mem_wen = 1'b1;
		data_signals.mem_wdata = data;
		data_signals.mem_waddr = addr;

		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.mem_wen = 1'b0;
		data_signals.mem_wdata = '0;
		data_signals.mem_waddr = '0;

		//TODO: some sort of checking?
		
	end
	endtask

endmodule
