/*
*   Copyright 2016 Purdue University
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
*   Filename:     tb/tb_rv32v_reg_file.sv
*
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/10/2021
*   Description:  testbench for vector register file
*/

`include "rv32v_reg_file_if.vh"

module tb_rv32v_reg_file ();
  import rv32v_types_pkg::*;
  import rv32i_types_pkg::*;

  parameter NUM_TESTS = 19;
  parameter PERIOD = 20;
  parameter DELAY = 20;
  logic testcase_num;
 
  logic error_found;
  logic CLK, nRST;

  rv32v_reg_file_if rfv_if();

  rv32v_reg_file DUT (.*);
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
    rfv_if.rd = 0;
    rfv_if.w_data = 0;
    rfv_if.wen = 0;
    nRST = 0;
    @(negedge CLK);
    nRST = 1;
  endtask

  task display_reg;
    input logic [4:0] rs1;

    // for (i = 0; i < VLENB; i++) begin
    $display("register[%d]: [%x] [%x] [%x] [%x] [%x] [%x] [%x] [%x]", rs1, DUT.registers[rs1][7], DUT.registers[rs1][6],DUT.registers[rs1][5],DUT.registers[rs1][4],DUT.registers[rs1][3],DUT.registers[rs1][2],DUT.registers[rs1][1],DUT.registers[rs1][0]);
    #2;
  endtask
  


  task write_reg;
    input [3:0] wen;
    input word_t [1:0] dat;
    input [4:0] wsel;

    @(negedge CLK);
    rfv_if.rd = wsel;
    rfv_if.w_data = dat;
    rfv_if.wen = wen;
    @(posedge CLK);
    #2;
    $info ("registers[%d]: %x", wsel, rfv_if.w_data);
    display_reg(wsel);
  endtask

  task read_reg;
    input [3:0] wen;
    input word_t [1:0] dat;
    input [4:0] rs1;
    input [4:0] rs2;

    @(negedge CLK);
    rfv_if.rs1 = rs1;
    rfv_if.rs2 = rs2;
    display_reg(rs1);
    $info ("registers[%d], rdat1: %x\nregisters[%d], rdat1: %x", rs1, rfv_if.rs1_data, rs2, rfv_if.rs2_data);
  endtask


  initial begin : MAIN
    testcase_num = 0;
    error_found = 0;
    #(DELAY);
    nRST = 0;
    #(DELAY);
    nRST = 1;


    //32 bit
    reset();
    for(int i = 0; i < 32; i+=8) begin
      write_reg(4'hF, {$urandom(), $urandom()}, i);
    end

    //16 bit
    reset();
    for(int i = 0; i < 32; i+=8) begin
      write_reg(4'h3, {$urandom(), $urandom()}, i);
    end
    
    //8 bit
    reset();
    for(int i = 0; i < 32; i+=8) begin
      write_reg(4'h1, {$urandom(), $urandom()}, i);
    end

    //wen disabled 
    reset();
    write_reg(4'h0, {$urandom(), $urandom()}, 0);

    reset();



    $finish;
  end : MAIN
endmodule

