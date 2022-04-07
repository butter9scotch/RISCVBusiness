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
*   Filename:     tb_l2_cache.sv
*
*   Created by:   Aedan Frazier		 , Dhruv Gupta		  ,  Rufat Imanov
*   Email:        frazie35@purdue.edu, gupta479@purdue.edu,	 rimanov@purdue.edu
*   Date Created: 07/18/2021
*   Description:  Testbench for parametrizable L1 Cache.
*/

`timescale 1ns / 10ps
`include "generic_bus_if.vh"

parameter CLK_PERIOD = 10;

module tb_l2_cache;
	// Defined Constants
	localparam RAM_WIDTH = 32;
	localparam ADDR_WIDTH = 32;
	localparam CLK_PERIOD = 10;
	localparam PROPAGATION_DELAY = 3;

	// Testbench Signals
	integer test_number;
	string test_case;
	logic tb_CLK;
	logic tb_nRST;

	//L1 side signals
	logic clear;
	logic clear_done;
	logic flush;
	logic flush_done;

	generic_bus_if l1_gen_bus_if(); // To L1 side.
	generic_bus_if mem_gen_bus_if(); // To Memory Controller

	// Clock generation block	
	always begin
		tb_CLK = 1'b0;
		#(CLK_PERIOD/2.0);
		tb_CLK = 1'b1;
		#(CLK_PERIOD/2.0);
  	end
	
	// L2 Cache Portmap
	l2_cache  #(.CACHE_SIZE(4096),
				.BLOCK_SIZE(4),
				.ASSOC(4),
				.NONCACHE_START_ADDR(32'h8000_0000)
				)
	l2 (.CLK(tb_CLK),
		.nRST(tb_nRST),
		.clear(clear),
		.clear_done(clear_done),
		.flush(flush),
		.flush_done(flush_done),
		.mem_gen_bus_if(mem_gen_bus_if),
		.proc_gen_bus_if(l1_gen_bus_if)
		);


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


	//Task to simulate data write by CPU
	// task l1_read;
	// 	input logic [ADDR_WIDTH-1:0] addr;
	// 	input logic []
	// begin
	// 	@(posedge tb_CLK);
	// 	for(int i = 0; i < 2; i++)begin
	// 		l1_gen_bus_if.ren = 1'b1;
	// 		l1_gen_bus_if.addr = {addr[31:3], 3'd0 + (4*i)};
	// 		wait(mem_gen_bus_if.busy);
	// 	end
		
	// 	@(posedge tb_CLK);
	// 	#(PROPAGATION_DELAY);
	// 	l1_gen_bus_if.ren = 1'b0;
	// 	l1_gen_bus_if._if.addr = '0;
	// end
	// endtask

	// task l1_wb;
	// 	input logic [ADDR_WIDTH-1:0] addr;
	// 	input logic [RAM_WIDTH-1:0] data;
	// begin
	// 	@(posedge tb_CLK);
	// 	#(PROPAGATION_DELAY);
	// 	l1_gen_bus_if.wen = 1'b1;
	// 	l1_gen_bus_if.wdata = data;
	// 	l1_gen_bus_if..addr = addr;

	// 	@(posedge tb_CLK);
	// 	#(PROPAGATION_DELAY);
	// 	l1_gen_bus_if.wen = 1'b0;
	// 	l1_gen_bus_if._if.wdata = '0;
	// 	l1_gen_bus_if._if.addr = '0;
	// end
	// endtask

	// Testbench Process
	initial begin
		test_number = 0;
		test_case = "";

		clear = 1'b0;
		flush = 1'b0;
		mem_gen_bus_if.busy = 1'b1;
		mem_gen_bus_if.rdata = '0;
		l1_gen_bus_if.ren = 1'b0;
		l1_gen_bus_if.wen = 1'b0;
		l1_gen_bus_if.wdata = '0;
		l1_gen_bus_if.byte_en = 1'b0;
		l1_gen_bus_if.addr = 32'h0000_0000;

		// TEST 00: Power-On and Reset Test
		test_number = 0;
		test_case = "Power-On and Reset";
		
		reset_dut();

		// TEST 01: Read to L1 Cache
		test_number++;
		test_case = "Write Miss to L1 Cache";
		reset_dut();
		

		@(negedge tb_CLK);
		tb_nRST 		       = 1'b1;
		l1_gen_bus_if.ren    = 1'b1;
		l1_gen_bus_if.wen    = 1'b0;
		l1_gen_bus_if.addr   = '0; // miss
		mem_gen_bus_if.rdata  = 32'hbeef0000;
		mem_gen_bus_if.busy   = 1'b0;
		@(posedge tb_CLK);
		mem_gen_bus_if.rdata  = 32'h0beef0000;
		@(posedge tb_CLK);
		mem_gen_bus_if.rdata  = 32'h00beef000;
		@(posedge tb_CLK);
		mem_gen_bus_if.rdata  = 32'h000beef00;
		wait(~l1_gen_bus_if.busy);
		mem_gen_bus_if.busy  = 1'b1;
		@(posedge tb_CLK);
		l1_gen_bus_if.wen  = 1'b0;





		l1_gen_bus_if.ren = 1'b1;
		
		@(posedge tb_CLK);
		#(PROPAGATION_DELAY);
		l1_gen_bus_if.ren = 1'b0;
		l1_gen_bus_if.addr = '0;

	
	$finish;
	end

endmodule
