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
`include "microop_buffer_if.vh"
`timescale 1ns/100ps

module tb_element_counter ();
  // import rv32i_types_pkg::*;
  import rv32i_types_pkg::*;

  parameter NUM_TESTS = 19;
  parameter PERIOD = 20;
  parameter DELAY = 20;
  int testnum;
  string testname = "";


 
  logic CLK, nRST;
  // logic [3:0] uop_if.LMUL;
  // logic uop_if.shift_ena;
  // logic uop_if.start;
  // logic uop_if.clear;
  // logic [31:0] uop_if.instr;
  // logic [31:0] microop;
  rtype_t vinstr;


  element_counter_if ele_if();
  microop_buffer_if uop_if();

  assign uop_if.shift_ena = ele_if.shift_ena;
  assign vinstr = rtype_t'(uop_if.microop);

  element_counter DUT (.*);
  microop_buffer buffer (.*); 
                        // LMUL,
                        // tb_shift_ena,
                        // tb_start,
                        // tb_clear,
                        // tb_instr,
                        // microop);
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
    ele_if.sew  = 0;
    ele_if.offset  = 0;
    ele_if.done = 0;
    ele_if.clear = 0;
    uop_if.LMUL = 0;
    uop_if.start = 0;
    uop_if.clear = 0;
    uop_if.instr = 0;


    @(posedge CLK);
    nRST = 1;
    @(posedge CLK);
  endtask

  task init_counter;
    input int vl;
    input sew_t sew;
    ele_if.vl = vl;
    ele_if.sew = sew;

  endtask
  task init_microop_buffer;
    input logic [3:0] LMUL_val;
    input int instr_val;
    @(negedge CLK);
    uop_if.start = 1;
    uop_if.instr = instr_val;
    uop_if.LMUL = LMUL_val;
    @(negedge CLK);
    uop_if.start = 0;
  endtask

  task count;
    input logic de_en;
    input logic stall;
    @(negedge CLK);
    ele_if.de_en = de_en;
    ele_if.stall = stall;

    if (ele_if.done) $write("Offset: %d", ele_if.offset);
  endtask

  task count_to;
    input int n;
    count(1, 0);
    repeat (n) @(posedge CLK);
  endtask


  task newtest;
    input string testname_arg;
    reset();
    testname = testname_arg;
    $info("\nTEST CASE %d: %s\n", testnum, testname);
    testnum+=1;
  endtask

  initial begin : MAIN
    testnum = 0;
    testname = "";

    newtest("SEW8");
    init_counter(128, SEW8);
    count_to(64);

    newtest("SEW16");
    init_counter(64, SEW16);
    count_to(32);

    newtest("SEW32");
    init_counter(32, SEW32);
    count_to(16);
/* ----------------------------------- */
    newtest("SEW8 len 63");
    init_counter(63, SEW8);
    count_to(32);

    newtest("SEW16 len 31");
    init_counter(31, SEW16);
    count_to(16);

    newtest("SEW32 len 15");
    init_counter(15, SEW32);
    count_to(8);
/* ----------------------------------- */
    newtest("SEW 8 LMUL 2 A TYPE");
    init_counter(32, SEW8);
    init_microop_buffer(2, 32'h57);
    count_to(16);

    newtest("SEW 32 LMUL 8 A TYPE");
    init_counter(32, SEW32);
    init_microop_buffer(8, 32'h57);
    count_to(16);
/* ----------------------------------- */
    newtest("SEW 32 LMUL 8 LS TYPE");
    init_counter(32, SEW32);
    init_microop_buffer(8, 32'h0C000007);
    count_to(16);
    newtest("LS TYPE IDX 01" );
    init_counter(32, SEW32);
    init_microop_buffer(8, 32'h04000027);
    count_to(16);
/* ----------------------------------- */
    newtest("SEW 32 EX RETURN");
    ele_if.vstart = 6;
    init_counter(16, SEW32);
    // init_microop_buffer(8, 32'h57);
    count_to(16);
    ele_if.ex_return = 1;
    @(negedge CLK);
    ele_if.ex_return = 0;

    count_to(4);
/* ----------------------------------- */
    newtest("CLEAR");
    // ele_if.vstart = 6;
    init_counter(16, SEW32);
    // init_microop_buffer(8, 32'h57);
    count_to(4);
    ele_if.clear = 1;
    uop_if.clear = 1;
    @(negedge CLK);
    ele_if.ex_return = 0;
    uop_if.clear = 0;
    count_to(4);

    $finish;
  end : MAIN
endmodule

