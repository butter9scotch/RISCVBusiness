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
*   Filename:     cocherence_ctrl_tb.sv
*
*   Created by:   Jiahao Xu
*   Email:        xu1392@purdue.edu
*   Date Created: 03/18/2022
*   Description:  Testbench for parametrizable L1/L2 coherence controller.
*/

`timescale 1ns/10ps
`include "generic_bus_if.vh"
`include "coherence_ctrl_if.vh"
//`include "rv32i_types_pkg.sv"

parameter CLK_PERIOD = 10; 
parameter BLOCK_SIZE = 2; 
parameter L2_LATENCY = 0; 

module cocherence_ctrl_tb(); 
	// clock generation. 
	logic CLK = 0;
	always #(CLK_PERIOD/2) CLK++;  

	// reset signal. 
	logic nRST = 0; 

	// interfaces. 
	coherence_ctrl_if ccif(); 

	// DUT instance.
	coherence_ctrl #(.BLOCK_SIZE(BLOCK_SIZE)) DUT(
		.CLK(CLK), 
		.nRST(nRST), 
		.ccif(ccif)
	); 

	task reset_dut; 
		@(negedge CLK) nRST = 1'b0; 
		#(CLK_PERIOD * 2) nRST = 1'b1; 
		@(posedge CLK); 
	endtask

	task l2_load_word(input word_t l2load);
		wait(ccif.l2REN) ccif.l2state = L2_BUSY; 
		#(L2_LATENCY * CLK_PERIOD) ccif.l2state = L2_ACCESS; 
		ccif.l2load = l2load; 
	endtask

	initial begin
		// set input signals. 
		ccif.dREN = '0; 
		ccif.dWEN = '0; 
		ccif.daddr = '0;
		ccif.dstore = '0; 
		ccif.cctrans = '0; 
		ccif.ccwrite = '0; 
		ccif.ccdirty = '0; 
		ccif.cchit = '0; 
		ccif.l2load = 32'hBAD0BAD0; 
		ccif.l2state = L2_FREE;  

		integer test_case_num = 0; 
		string test_case_info = "initial reset"; 
		reset_dut();
		$display("I: Test Case %2d Controller Reset passed.\n", test_case_num); 
		
		test_case_num ++; 
		test_case_info = "I->E, -/-";
		$finish; 
	end
endmodule