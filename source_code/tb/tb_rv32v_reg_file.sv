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
  int testnum;
  string testname = "";

 
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
    rfv_if.vd = 0;
    rfv_if.w_data = 0;
    rfv_if.wen = 0;
    rfv_if.vs1_offset = 0;
    rfv_if.vs2_offset = 0;
    rfv_if.vd_offset  = 0;
    rfv_if.write_single_bit = 0;
    nRST = 0;
    @(posedge CLK);
    nRST = 1;
  endtask

  task display_reg;
    input logic [4:0] rs;

    int i;
    $write("register[%d]: ", rs);
    for (i = VLENB - 1; i >= 0; i--) begin
      $write("[%x] ", DUT.registers[rs][i]);
    end
    $write("\n");
    // $display("[%x] [%x] [%x] [%x] [%x] [%x] [%x] [%x]", DUT.registers[vs1][7], DUT.registers[vs1][6],DUT.registers[vs1][5],DUT.registers[vs1][4],DUT.registers[vs1][3],DUT.registers[vs1][2],DUT.registers[vs1][1],DUT.registers[vs1][0]);
    // #2;
  endtask
  


  task write_reg;
    input wen;
    input sew_t sew;
    input word_t [1:0] dat;
    input [4:0] wsel;
    input offset_t vd_offset;

    @(negedge CLK);
    rfv_if.vd = wsel;
    rfv_if.w_data = dat;
    rfv_if.wen = wen;
    rfv_if.wb_sew = sew;
    rfv_if.write_single_bit = 0;
    

    rfv_if.vd_offset = vd_offset;

    @(posedge CLK);
    #2;
    $write ("WRITE to registers[%d], offset(%d) : [%x], [%x]\n", wsel, vd_offset, rfv_if.w_data[1], rfv_if.w_data[0]);
    display_reg(wsel);
  endtask


  task read_reg;
    input sew_t sew;
    input [4:0] vs1;
    input [4:0] vs2;
    input offset_t vs1_offset;
    input offset_t vs2_offset;

    @(negedge CLK);
    rfv_if.de_sew = sew;
    rfv_if.vs1 = vs1;
    rfv_if.vs2 = vs2;

    rfv_if.vs1_offset = vs1_offset;
    rfv_if.vs2_offset = vs2_offset;

    display_reg(vs1);
    $write ("READ: registers[%d], rdat1: [%x], [%x]\n \
registers[%d], rdat2: [%x], [%x]\n", vs1, rfv_if.vs1_data[1], rfv_if.vs1_data[0], vs2, rfv_if.vs2_data[1], rfv_if.vs2_data[0]);
  endtask

  task newtest;
    input string testname;
    reset();
    $info("\nTEST CASE %d: %s\n", testnum, testname);
    testnum+=1;
  endtask

  task write_with_offset;
    input sew_t sew;

    word_t [1:0] data;
    word_t [1:0] data_temp;
    int max_cnt;
    int reg_idx;

    data = {$urandom(), $urandom()};
    data_temp = data;
    max_cnt = 128 / (8 << sew);
    reg_idx = 0;

    for(int el_idx = 0; el_idx < max_cnt; el_idx+=2) begin

      // data = {data[1] >> (), data[0] >> ()};
      write_reg(1, sew, data, reg_idx, el_idx);
      read_reg(sew, reg_idx, reg_idx, el_idx, el_idx);
      // data = next_data;
    end
  endtask


  task write_single_bit;
    input wen;
    input word_t [1:0] dat;
    input int wsel;
    input int vd_offset;

    @(negedge CLK);
    rfv_if.vd = wsel;
    rfv_if.w_data = dat;
    rfv_if.wen = wen;
    rfv_if.wb_sew = SEW8;
    rfv_if.write_single_bit = 1;

    rfv_if.vd_offset = vd_offset;
    rfv_if.vs1_offset = vd_offset;
    rfv_if.vs2_offset = vd_offset;

    @(posedge CLK);
    #2;
    $write ("WRITE SINGLE BIT to registers[%d], offset(%d) : [%x], [%x]\n", wsel, vd_offset, rfv_if.w_data[1], rfv_if.w_data[0]);
    if (rfv_if.vs1_mask[0] != rfv_if.w_data[0][0]) begin
      $info("vs1_mask[0] bad"); end
    if (rfv_if.vs1_mask[1] != rfv_if.w_data[1][0]) begin
      $info("vs1_mask[1] bad"); end
    if (rfv_if.vs2_mask[0] != rfv_if.w_data[0][0]) begin
      $info("vs1_mask[0] bad"); end
    if (rfv_if.vs2_mask[1] != rfv_if.w_data[1][0]) begin
      $info("vs1_mask[1] bad"); end
  endtask

  task write_single_bit_top_level;
    // input sew_t sew;

    word_t [1:0] data;
    word_t d;
    int max_cnt;
    int reg_idx;

    
    // data = {32'hFFFFFFFF >> 1, 32'hFFFFFFFF};
    // max_cnt = 128 / (8 << sew);
    reg_idx = 0;

    //
    //first half
    //
    // int i;
    for (int i = 0; i < 4; i++) begin

      d = $urandom();
      data[0] = d;
      data[1] = d >> 1;
      for(int el_idx = 0; el_idx < 32; el_idx+=2) begin
        write_single_bit(1, data, reg_idx, el_idx);
        data = {data[1] >> 2, data[0] >> 2};
      end
      display_reg(0);
    end
    
    // $write("FIRST WORD DONE\n");
    
    //
    //second half
    //
    d = $urandom();
    data = {d >> 1, d};
    // data = {32'hFFFFFFFF, 32'hFFFFFFFF};

    for(int el_idx = 32; el_idx < 64; el_idx+=2) begin
      // $write("\nWRITE %d: [%x], [%x]", el_idx, data[1], data[0]);
      write_single_bit(1, data, reg_idx, el_idx);
      data = {data[1] >> 2, data[0] >> 2};
    end

    $write("SECOND WORD DONE\n");
    display_reg(0);

  endtask


  initial begin : MAIN
    testnum = 0;
    testname = "";
    error_found = 0;
    #(DELAY);
    nRST = 0;
    #(DELAY);
    nRST = 1;


    newtest("write disable");
    write_reg(4'h0, SEW32, {$urandom(), $urandom()}, 0, 0);

    //32 bit
    newtest("32 bit, no offset");
    for(int i = 0; i < 32; i+=8) begin
      write_reg(4'hF, SEW32, {$urandom(), $urandom()}, i, 0);
      read_reg(SEW32, i, i, 0, 0);
    end

    //16 bit
    newtest("16 bit, no offset");
    for(int i = 0; i < 32; i+=8) begin
      write_reg(4'h3, SEW16, {$urandom(), $urandom()}, i, 0);
      read_reg(SEW16, i, i, 0, 0);
    end
    
    //8 bit
    newtest("8 bit, no offset");
    for(int i = 0; i < 32; i+=8) begin
      write_reg(4'h1, SEW8, {$urandom(), $urandom()}, i, 0);
      read_reg(SEW8, i, i, 0, 0);
    end

    newtest("32 bit, with offset");
    write_with_offset(SEW32);
    
    newtest("16 bit, with offset");
    write_with_offset(SEW16);

    newtest("8 bit, with offset");
    write_with_offset(SEW8);

    newtest("SINGLE BITS");
    write_single_bit_top_level();

    // newtest("32 bit, with offset");
    // for(int el_idx = 0; el_idx < 4; el_idx+=2) begin
    //   write_reg(4'h1, SEW32, {$urandom(), $urandom()}, 0, el_idx);
    //   read_reg(SEW32, 0, 0, el_idx, el_idx);
    // end


    // newtest("16 bit, with offset");
    // for(int el_idx = 0; el_idx < 8; el_idx+=2) begin
    //   write_reg(4'h1, SEW16, {$urandom(), $urandom()}, 0, el_idx);
    //   read_reg(SEW16, 0, 0, el_idx, el_idx);
    // end


    // newtest("8 bit, with offset");
    // for(int el_idx = 0; el_idx < 16; el_idx+=2) begin
    //   write_reg(4'h1, SEW8, {$urandom(), $urandom()}, 0, el_idx);
    //   read_reg(SEW8, 0, 0, el_idx, el_idx);
    // end

    $finish;
  end : MAIN
endmodule

