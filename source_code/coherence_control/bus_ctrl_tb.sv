/*
*	Copyright 2022 Purdue University
*		
*	Licensed under the Apache License, Version 2.0 (the "License");
*	you may not use this file except in compliance with the License.
*	You may obtain a copy of the License at
*		
*	    http://www.apache.org/licenses/LICENSE-2.0
*		
*	Unless required by applicable law or agreed to in writing, software
*	distributed under the License is distributed on an "AS IS" BASIS,
*	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*	See the License for the specific language governing permissions and
*	limitations under the License.
*
*
*	Filename:     bus_ctrl.sv
*
*	Created by:   Jimmy Mingze Jin
*	Email:        jin357@purdue.edu
*	Date Created: 11/01/2022
*	Description:  Bus controller basic TB
*/

`timescale 1ns/10ps
`include "bus_ctrl_if.vh"

parameter CLK_PERIOD = 10; 
parameter BLOCK_SIZE = 2; 
parameter L2_LATENCY = 8; 
parameter TB_CPUS = 4; 

module bus_ctrl_tb(); 
	// CLK/nRST
	logic CLK = 0, nRST = 1;
	always #(CLK_PERIOD/2) CLK++;  

	// testbench variables.
	integer test_case_num = 0; 
	integer i = 0; 
	string test_case_info = "initial reset"; 
	logic tb_err = 0; 

	// interfaces. 
	bus_ctrl_if ccif(); 

	// DUT instance.
	bus_ctrl #(.DOUBLE_BLOCK_SIZE(BLOCK_SIZE/2), .CPUS(TB_CPUS)) DUT(
		.CLK(CLK), 
		.nRST(nRST), 
		.ccif(ccif)
	); 

	task reset_dut; 
		@(negedge CLK) nRST = 1'b0; 
		#(CLK_PERIOD * 2) nRST = 1'b1; 
		@(posedge CLK); 
	endtask

	task initialize_inputs;
		ccif.dREN = 0; 
		ccif.dWEN = '0; 
		ccif.daddr = '0;
		ccif.dstore = '0; 
		ccif.cctrans = '0; 
		ccif.ccwrite = '0; 
		ccif.ccsnoophit = '0; 
		ccif.ccexclusivehit = '0; 
		ccif.l2load = 64'hBAD1BAD1BAD0BAD0; 
		ccif.l2state = L2_FREE;  
	endtask

	// from coherence_ctrl_tb
	task l2_load_word(input longWord_t l2load);
		wait(ccif.l2REN == 1'b1);  
		ccif.l2state = L2_BUSY; 
		#(L2_LATENCY * CLK_PERIOD); 
		ccif.l2state = L2_ACCESS; 
		ccif.l2load = l2load; 
	endtask

	// from coherence_ctrl_tb
	task l2_store_word(input longWord_t expected_l2store);
		wait(ccif.l2WEN == 1'b1); 
			// check the word written to l2. 
		if (ccif.l2store != word_t'(expected_l2store)) begin
			tb_err = 1'b1; 
		end
		ccif.l2state = L2_BUSY; 
		#(L2_LATENCY * CLK_PERIOD); 
		ccif.l2state = L2_ACCESS; 
	endtask

	task transfer(input longWord_t data, logic srcid, dstid); 
		ccif.dstore[srcid] = data; 
		ccif.dload[dstid] = ccif.dstore[srcid]; 
		wait(~ccif.dwait[dstid]); 
		//#(CLK_PERIOD); 
	endtask

	task check_dload(input word_t expected_word, logic expected_ccexclusive, int prid);
		wait(ccif.dwait[prid] == 1'b0);
		if (word_t'(ccif.dload[prid]) != expected_word) begin
			$display("E: ccif.dload[%1d]: %8h, but expecting: %8h\n", prid, ccif.dload[prid], expected_word);
			tb_err = 1'b1; 
		end
		if (ccif.ccexclusive[prid] != expected_ccexclusive) begin 
			$display("E: wrong ccif.exclusive[%1d]\n", prid); 
			tb_err = 1'b1; 
		end
		wait(ccif.l2REN == 1'b0);  
		ccif.l2state = L2_FREE; 
	endtask

	initial begin
		// set input signals. 
		initialize_inputs(); 
		reset_dut();
		$display("I: Test Case %2d %s passed.", test_case_num, test_case_info); 

    	/***************************************************************************
    	* Set 1: Simulate the behaviour of 1 processor's read miss  			   *
    	****************************************************************************/
		// all other caches do not have the data (no supplier)
		// TODO

		// one other cache has the data (supplier = E, M)
		// TODO

		// multiple other caches has the data (supplier = S)
		// TODO
		
    	/***************************************************************************
    	* Set 2: Simulate the behaviour of 1 processor's write miss; no eviction   *
    	****************************************************************************/
		// all other caches do not have the data (no supplier)
		// TODO

		// one other cache has the data (supplier = E, M)
		// TODO

		// multiple other caches has the data (supplier = S)
		// TODO

		// current cache has data in shared (special write_miss)
		// TODO

		/***************************************************************************
    	* Set 3: Simulate the behaviour of 1 processor's eviction 				   *  
    	****************************************************************************/
		// verify that we go through and write our data
		// TODO
		
    	/***************************************************************************
    	* Set 4: Simulate the behaviour of multiple concurrent requests			   *
    	****************************************************************************/
		// simulate operation of 1 bus transaction with multiple read requests
		// TODO

		// simulate operation of 1 bus transaction with multiple read requests and
		// one eviction request
		// TODO

		$finish; 
	end
endmodule