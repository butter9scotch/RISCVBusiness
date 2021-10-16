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
*   Filename:     tb/tb_element_counter.sv
*
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/13/2021
*   Description:  testbench for vector element counter
*/

`include "element_counter_if.vh"

module tb_element_counter ();
  import rv32v_types_pkg::*;
  import rv32i_types_pkg::*;

  parameter NUM_TESTS = 19;
  parameter PERIOD = 20;
  parameter DELAY = 20;
  int testnum;
  string testname = "";

 
  logic error_found;
  logic CLK, nRST;

  element_counter_if ele_if();

  element_counter DUT (.CLK(CLK), .nRST(nRST), .ele_if(ele_if));
  //   .rfv_if(CLK, nRST, rfv_if)
  // );

  initial begin : CLK_INIT
    CLK = 1'b0;
    nRST = 1;
  end : CLK_INIT

  always begin : CLK_GEN
    #(PERIOD/2) CLK = ~CLK;
  end : CLK_GEN
 
  task reset;

    @(negedge CLK);
    nRST = 0;
    ele_if.vstart  = 0;
    ele_if.vl  = 0;
    ele_if.stall  = 0;
    ele_if.ex_return  = 0;
    ele_if.de_en  = 0;
    ele_if.reset_idx  = 0;
    ele_if.sew  = 0;
    ele_if.offset  = 0;
    ele_if.micro_op_vl  = 0;
    ele_if.done = 0;

    @(posedge CLK);
    nRST = 1;
  endtask

  task init_counter;
    input int vl;
    input sew_t sew;
    ele_if.vl = vl;
    ele_if.sew = sew;
  endtask

  task count;
    input logic de_en;
    input logic stall;
    @(negedge CLK);
    ele_if.de_en = de_en;
    ele_if.stall = stall;

    if (ele_if.done) $write("Offset: %d, micro_op_vl: %d", ele_if.offset, ele_if.micro_op_vl);
  endtask

  task newtest;
    input string testname;
    reset();
    $info("\nTEST CASE %d: %s\n", testnum, testname);
    testnum+=1;
  endtask

  initial begin : MAIN
    testnum = 0;
    testname = "";
    error_found = 0;

    newtest("test1");
    init_counter(8, SEW8);
    count(1, 0);
    repeat (4) @(posedge CLK);

    $finish;
  end : MAIN
endmodule

