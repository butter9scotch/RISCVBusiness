`timescale 1ns/1ns
`include "generic_bus_if.vh"

parameter CLK_PERIOD = 10;
			    
module tb_l1_cache;
    logic CLK, nRST;
    initial CLK  = 1'b0;
    always #(CLK_PERIOD/2) begin
	CLK = ~CLK;    
    end
    
/* -----\/----- EXCLUDED -----\/-----
module l1_cache #(
    parameter CACHE_SIZE          = 1024, // must be power of 2, in bytes, max 2^32
    parameter BLOCK_SIZE          = 2, // must be power of 2, max 32
    parameter ASSOC               = 1, // 1 or 2 so far
    parameter NONCACHE_START_ADDR = 32'h8000_0000
)
(
    input logic CLK, nRST,
    input logic clear, flush,
    output logic clear_done, flush_done,
    generic_bus_if.cpu mem_gen_bus_if,
    generic_bus_if.generic_bus proc_gen_bus_if

);
 -----/\----- EXCLUDED -----/\----- */
    
    logic clear, flush, clear_done, flush_done;
    generic_bus_if mem_gen_bus_if(), proc_gen_bus_if();
    
    l1_cache #(.CACHE_SIZE(1024), .BLOCK_SIZE(2), .ASSOC(2), .NONCACHE_START_ADDR(32'h8000_0000)) DUT (.*);
    test TB_DUT(clear_done, flush_done, CLK, clear, flush, nRST, mem_gen_bus_if, proc_gen_bus_if);
    // test TB_DUT(.*);
 
endmodule // tb_l1_cache

program test(
    input logic  clear_done, flush_done, CLK, 
    output logic clear, flush, nRST, 
    generic_bus_if.generic_bus mem_gen_bus_if,
    generic_bus_if.cpu proc_gen_bus_if
);

/* -----\/----- EXCLUDED -----\/-----
    modport cpu (
    input rdata, busy,
    output addr, ren, wen, wdata, byte_en
    );
 -----/\----- EXCLUDED -----/\----- */

    integer 	 test_num;
    string 	 test_case;;
    
    initial begin
	// Test case:0, initialization
	test_num 		 = 0;
	test_case 		 = "Initialization";
	nRST 			 = 1'b1;
	clear 			 = 1'b0;
	flush 			 = 1'b0;
	mem_gen_bus_if.busy 	 = 1'b1;
	mem_gen_bus_if.rdata 	 = '0;
	proc_gen_bus_if.addr 	 = '0;
	proc_gen_bus_if.ren 	 = 1'b0;
	proc_gen_bus_if.wen 	 = 1'b0;
	proc_gen_bus_if.wdata 	 = '0;
	proc_gen_bus_if.byte_en  = '0;
	
	#1;
	
	// Test case: 1, Reset
	test_num++;
	test_case  = "Reset";
	@(negedge CLK);
	nRST  = 1'b0;

	// Test case: 2, Write miss
	@(negedge CLK);
	test_num++;
	test_case 	       = "Write miss";
	nRST 		       = 1'b1;
	proc_gen_bus_if.ren    = 1'b0;
	proc_gen_bus_if.wen    = 1'b1;
	proc_gen_bus_if.addr   = '0; // miss
	proc_gen_bus_if.wdata  = 32'hDEAD_DEAF;
	wait(mem_gen_bus_if.ren);
	assert(mem_gen_bus_if.addr == proc_gen_bus_if.addr) else $error("Test case: %s, test num: %0d, address from CPU does not match with incoming to main memory", test_case, test_num);
	mem_gen_bus_if.rdata  = 32'hBEEF_BEEF;
	mem_gen_bus_if.busy   = 1'b0;
	@(posedge CLK);
	assert(mem_gen_bus_if.addr == proc_gen_bus_if.addr + 4) else $error("Test case: %s, test num: %0d, second word address is wrong", test_case, test_num);
	mem_gen_bus_if.rdata  = 32'hFFFF_AAAA;
	wait(~proc_gen_bus_if.busy);
	mem_gen_bus_if.busy  = 1'b1;
	@(posedge CLK);
	proc_gen_bus_if.wen  = 1'b0;
	
	// Test case: 3, Read back from 32'd0
	#CLK_PERIOD;
	test_num++;
	test_case  = "Read back";
	@(posedge CLK);
	proc_gen_bus_if.ren  = 1'b1;
	wait(~proc_gen_bus_if.busy);
	assert(proc_gen_bus_if.rdata == 32'hDEAD_DEAF) else $error("Test case: %s, test num: %0d, read %h, expected %h,  value from cache after miss", test_case, test_num, proc_gen_bus_if.rdata, 32'hDEAD_DEAF);
	proc_gen_bus_if.ren = 1'b0;

	// Test case 5, cache replace
	#CLK_PERIOD;
	test_num++;
	test_case  = "Cache Replace";
	@(posedge CLK);
	proc_gen_bus_if.addr   = 32'h0FFF_0000;
	proc_gen_bus_if.wdata  = 32'hAAAA_AAAA;
	proc_gen_bus_if.wen    = 1'b1;
	mem_gen_bus_if.busy    = 1'b0;
	mem_gen_bus_if.rdata   = 32'hCCCC_CCCC;
	wait(~proc_gen_bus_if.busy);
	@(posedge CLK);
	proc_gen_bus_if.wdata  = 32'hBBBB_BBBB;
	proc_gen_bus_if.addr   = 32'h0AAA_0000; #1;
	wait(~proc_gen_bus_if.busy);
	@(posedge CLK);
	proc_gen_bus_if.wen  = 1'b0;
	@(posedge CLK);
	proc_gen_bus_if.ren  = 1'b1; #1;
	wait(~proc_gen_bus_if.busy);
	assert(proc_gen_bus_if.rdata == 32'hBBBB_BBBB) else $error("Test case: %s, test num: %0d, read %h, expected 32'hBBBB_BBBB",test_case,test_num,proc_gen_bus_if.rdata);
	@(posedge CLK);
	
	
	



	
/* -----\/----- EXCLUDED -----\/-----
	// Test case: 4, exhaustive write and then read all
	#CLK_PERIOD;
	test_num++;
	test_case  = "Exhaustive write/read";
	@(posedge CLK);
	proc_gen_bus_if.wen    = 1'b1;
	proc_gen_bus_if.wdata  = '0;
	proc_gen_bus_if.addr   = '0;
	mem_gen_bus_if.busy    = 1'b0;
	mem_gen_bus_if.rdata   = '0;
	for(integer i = 0; i < 32'h8000_0000; i = i + 4) begin
	    wait(~proc_gen_bus_if.busy);
	    @(posedge CLK);
	    proc_gen_bus_if.wdata++;
	    proc_gen_bus_if.addr  = i;
	end // for (integer i = 0; i < 32'h8000_0000; i = i + 4)
 -----/\----- EXCLUDED -----/\----- */
		
	$finish;	
    end    
    
 
endprogram // test
