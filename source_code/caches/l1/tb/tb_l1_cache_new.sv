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
		logic clear;
		logic clear_done;
		logic flush;
		logic flush_done;
		generic_bus_if mem_gen_if();
		generic_bus_if proc_gen_if();
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


	// Task to simulate data write by CPU
	task cpu_data_write;
		input logic [RAM_WIDTH-1:0] data;
		input logic [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.proc_gen_if.wen = 1'b1;
		data_signals.proc_gen_if.wdata = data;
		data_signals.proc_gen_if.addr = addr;

		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.proc_gen_if.wen = 1'b0;
		data_signals.proc_gen_if.wdata = '0;
		data_signals.proc_gen_if.addr = '0;
	end
	endtask

	// Task to simulate data read by CPU
	task cpu_data_read;
		input logic [RAM_WIDTH-1:0] data;  // Not necessary, can be used for checks
		input logic [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.proc_gen_if.ren = 1'b1
		data_signals.proc_gen_if.addr = addr;

		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		data_signals.proc_gen_if.ren = 1'b0;
		data_signals.proc_gen_if.addr = '0;
	end
	endtask


	// Task to simulate instruction read by CPU
	task cpu_data_read;
		input logic [RAM_WIDTH-1:0] data;  // Not necessary, can be used for checks
		input logic [ADDR_WIDTH-1:0] addr;
	begin
		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		inst_signals.proc_gen_if.ren = 1'b1
		inst_signals.proc_gen_if.addr = addr;

		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		inst_signals.proc_gen_if.ren = 1'b0;
		inst_signals.proc_gen_if.addr = '0;
	end
	endtask

	// Data Cache Portmap
	l1_cache #(.CACHE_SIZE(2048),
	.BLOCK_SIZE(4),
	.ASSOC(4),
	.NONCACHE_START_ADDR(32'h8000_0000))
	DATA_CACHE (.CLK(tb_CLK),
	.nRST(tb_nRST),
	.clear(data_signals.clear),
	.clear_done(data_signals.clear_done),
	.flush(data_signals.flush),
	.flush_done(data_signals.flush_done),
	.mem_gen_bus_if(data_signals.mem_gen_bus_if),
	.proc_gen_bus_if(data_signals.proc_gen_bus_if));

	// Instruction Cache Portmap
	l1_cache #(.CACHE_SIZE(1024),
	.BLOCK_SIZE(2),
	.ASSOC(2),
	.NONCACHE_START_ADDR(32'h8000_0000))
	INST_CACHE (.CLK(tb_CLK),
	.nRST(tb_nRST),
	.clear(inst_signals.clear),
	.clear_done(inst_signals.clear_done),
	.flush(inst_signals.flush),
	.flush_done(inst_signals.flush_done),
	.mem_gen_bus_if(inst_signals.mem_gen_bus_if),
	.proc_gen_bus_if(inst_signals.proc_gen_bus_if));

	// Clock generation block	
	always begin
        	tb_CLK = 1'b0;
    		#(CLK_PERIOD/2.0);
    		tb_CLK = 1'b1;
    		#(CLK_PERIOD/2.0);
  	end

endmodule
