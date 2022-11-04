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
parameter L2_LATENCY = 4; 
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
	logic [1:0] supplier = 0;

	// interfaces. 
	bus_ctrl_if ccif(); 

	// DUT instance.
	bus_ctrl #(.DOUBLE_BLOCK_SIZE(BLOCK_SIZE/2), .CPUS(TB_CPUS)) DUT(
		.CLK(CLK), 
		.nRST(nRST), 
		.ccif(ccif)
	); 

	// resets the DUT
	task reset_dut; 
		@(negedge CLK) nRST = 1'b0; 
		#(CLK_PERIOD * 2) nRST = 1'b1; 
		@(posedge CLK); 
	endtask

	// initialize to inactive for all inputs to bus
	task initialize_inputs;
		ccif.dREN = 0; 
		ccif.dWEN = '0; 
		ccif.daddr = '0;
		ccif.dstore = 64'hBADBADBAD; 
		ccif.cctrans = '0; 
		ccif.ccwrite = '0; 
		ccif.ccsnoophit = '0; 
		ccif.ccIsPresent = '0;
		ccif.ccdirty = '0;
		ccif.l2load = 64'hBADBADBAD;
		ccif.l2state = L2_FREE;
		#(CLK_PERIOD * 2);
	endtask

	/*
	* from Jiahao's coherence_ctrl_tb
	* given a 64 bit longWord, 
	* simulates putting a particular longWord from L2 onto the bus
	*/
	task l2_load(input longWord_t l2load);
		wait(ccif.l2REN == 1'b1);
		ccif.l2state = L2_BUSY; 
		#(L2_LATENCY * CLK_PERIOD); 
		ccif.l2state = L2_ACCESS; 
		ccif.l2load = l2load;
		wait(ccif.l2REN == 1'b0);
			ccif.l2state = L2_FREE; 
	endtask

	/*
	* from Jiahao's coherence_ctrl_tb
	* given a 64 bit longWord, 
	* simulates putting a particular longWord from bus to L1
	*/
	task cachetransfer(input longWord_t data, logic[1:0] srcid, dstid); 
		ccif.dstore[srcid] = data;
		ccif.ccsnoophit[srcid] = 1;
		wait(~ccif.dwait[dstid]);
		#(CLK_PERIOD/2);
		if (ccif.dload[dstid] != data)
			tb_err = 1'b1;
		#(CLK_PERIOD/2);
	endtask

	/*
	* from Jiahao's coherence_ctrl_tb
	* given a 64 bit longWord, 
	* checks a load based on expected stimuli
	*/
	task check_dload(input longWord_t expected_data, logic expected_ccexclusive, int prid);
		wait(~ccif.dwait[prid]);
		if (word_t'(ccif.dload[prid]) != expected_data) begin
			$display("E: ccif.dload[%1d]: %8h, but expecting: %8h\n", prid, ccif.dload[prid], expected_data);
			tb_err = 1'b1; 
		end
		if (ccif.ccexclusive[prid] != expected_ccexclusive) begin 
			$display("E: wrong ccif.ccexclusive[%1d]\n", prid); 
			tb_err = 1'b1; 
		end
	endtask

	/*
	* based on Jiahao's coherence_ctrl_tb
	* given a 64 bit longWord, 
	* simulates putting a particular longWord from bus to L2
	* analogous to a cache-eviction
	*/
	task l2_store(input longWord_t expected_l2store);
		wait(ccif.l2WEN == 1'b1);
		if (ccif.l2store != word_t'(expected_l2store))
			tb_err = 1'b1; 
		ccif.l2state = L2_BUSY; 
		#(L2_LATENCY * CLK_PERIOD); 
		ccif.l2state = L2_ACCESS;
		#(CLK_PERIOD);			// stay in access for a clk
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
		initialize_inputs();
		test_case_num++;
		test_case_info = "I -> E, no transition";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 1;
		ccif.ccsnoophit = '0;
		ccif.daddr[0] = word_t'(19);
		// go through and check outputs
		for (i = 0; i < BLOCK_SIZE/2; i++) begin
			l2_load(longWord_t'(i + 1));
			check_dload(longWord_t'(i + 1), 1, 0);
		end

		// one other cache has the data (supplier = E)
		initialize_inputs();
		test_case_num++;
		test_case_info = "I -> S, E -> S";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 1;
		ccif.ccsnoophit = '0;
		ccif.daddr[0] = word_t'(19);
		// go through and check outputs
		for (i = 0; i < BLOCK_SIZE/2; i++) begin
			supplier = (!(i % 4) ? 1 : (i % 4));
			ccif.ccIsPresent[supplier] = 1;
			cachetransfer(longWord_t'(i + 1), supplier, 0);
			check_dload(longWord_t'(i + 1), 0, 0);
		end

		// one other cache has the data (supplier = M)
		initialize_inputs();
		test_case_num++;
		test_case_info = "I -> S, M -> S";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 1;
		ccif.ccsnoophit = '0;
		ccif.daddr[0] = word_t'(19);
		// go through and check outputs
		for (i = 0; i < BLOCK_SIZE/2; i++) begin
			supplier = (!(i % 4) ? 1 : (i % 4));
			ccif.ccdirty[supplier] = 1;
			cachetransfer(longWord_t'(i + 1), supplier, 0);
			check_dload(longWord_t'(i + 1), 0, 0);
			l2_store(longWord_t'(i + 1));
		end

		// multiple other caches has the data (other caches = S)
		initialize_inputs();
		test_case_num++;
		test_case_info = "I -> S, no transition";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 1;
		ccif.ccsnoophit = '0;
		ccif.dstore[1] = 5;
		ccif.daddr[0] = word_t'(19);
		// go through and check outputs
		for (i = 0; i < BLOCK_SIZE/2; i++) begin
			ccif.ccIsPresent = 4'b1100;
			l2_load(longWord_t'(i + 1));
			check_dload(longWord_t'(i + 1), 0, 0);
		end

    /***************************************************************************
    * Set 2: Simulate the behaviour of 1 processor's write miss; no eviction   *
    ****************************************************************************/
		// all other caches do not have the data (no supplier)
		initialize_inputs();
		test_case_num++;
		test_case_info = "I -> M, no transition";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 1;
		ccif.ccsnoophit = '0;
		ccif.daddr[0] = word_t'(19);
		ccif.ccwrite[0] = 1;
		// go through and check outputs
		for (i = 0; i < BLOCK_SIZE/2; i++) begin
			l2_load(longWord_t'(i + 1));
			check_dload(longWord_t'(i + 1), 1, 0);		// need to check ccinv
		end

		// one other cache has the data (supplier = E)
		initialize_inputs();
		test_case_num++;
		test_case_info = "I -> M, E -> I";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 1;
		ccif.ccsnoophit = '0;
		ccif.daddr[0] = word_t'(19);
		ccif.ccwrite[0] = 1;
		// go through and check outputs
		for (i = 0; i < BLOCK_SIZE/2; i++) begin
			supplier = (!(i % 4) ? 1 : (i % 4));
			ccif.ccIsPresent[supplier] = 1;
			cachetransfer(longWord_t'(i + 1), supplier, 0);
			check_dload(longWord_t'(i + 1), 1, 0);	// does not matter					// need to check ccinv
		end

		// one other cache has the data (supplier = M)
		initialize_inputs();
		test_case_num++;
		test_case_info = "I -> M, M -> I";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 1;
		ccif.ccsnoophit = '0;
		ccif.daddr[0] = word_t'(19);
		ccif.ccwrite[0] = 1;
		// go through and check outputs
		for (i = 0; i < BLOCK_SIZE/2; i++) begin
			supplier = (!(i % 4) ? 1 : (i % 4));
			ccif.ccsnoophit[supplier] = 1;
			ccif.ccdirty[supplier] = 1;
			ccif.ccIsPresent[supplier] = 1;
			cachetransfer(longWord_t'(i + 1), supplier, 0);
			check_dload(longWord_t'(i + 1), 1, 0);
		end

		// multiple other caches has the data (other caches = S)
		initialize_inputs();
		test_case_num++;
		test_case_info = "I -> M, S -> I";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 1;
		ccif.ccsnoophit = '0;
		ccif.daddr[0] = word_t'(19);
		ccif.ccwrite[0] = 1;
		// go through and check outputs
		for (i = 0; i < BLOCK_SIZE/2; i++) begin
			ccif.ccIsPresent[supplier] = 1;
			l2_load(longWord_t'(i + 1));
			check_dload(longWord_t'(i + 1), 1, 0);		// need to check ccinv
		end


		// cache has data in shared (special write_miss)
		initialize_inputs();
		test_case_num++;
		test_case_info = "S -> M, x -> I";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dREN[0] = 0;				// indicate that we are going S -> M 
		ccif.ccsnoophit = '0;			// does not matter
		ccif.daddr[0] = word_t'(19);
		ccif.ccwrite[0] = 1;

		// TODO, check invalidation
		#(CLK_PERIOD * 2)


	/***************************************************************************
    * Set 3: Simulate the behaviour of 1 processor's eviction                  *  
    ****************************************************************************/
		// verify that we go through and write our data
		initialize_inputs();
		test_case_num++;
		test_case_info = "cache eviction or flush";
		// set stimuli
		ccif.cctrans[0] = 1;
		ccif.dWEN[0] = 1;				// writeback 
		ccif.ccsnoophit = '0;		// does not matter
		ccif.daddr[0] = word_t'(19);
		ccif.ccwrite[0] = 1;

		// TODO

		
    /***************************************************************************
    * Set 4: Simulate the behaviour of multiple concurrent requests            *
    ****************************************************************************/
		// simulate operation of 1 bus transaction with multiple read requests
		test_case_num++;
		test_case_info = "arbitration between multiple read requests";

		// simulate operation of 1 bus transaction with multiple read requests and
		// one eviction request
		test_case_num++;
		test_case_info = "arbitration between multiple read requests and a write request";
		$finish; 
	end
endmodule