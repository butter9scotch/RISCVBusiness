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
*   Filename:     tb/tb_vector_control_unit.sv
*
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/13/2021
*   Description:  testbench for vector control unit
*/

`include "rv32v_fetch2_decode_if.vh"
`include "rv32v_decode_execute_if.vh"
`include "rv32v_reg_file_if.vh"
`include "rv32v_hazard_unit_if.vh"
`include "prv_pipeline_if.vh"



// `include "instruction.svh"

module tb_rv32v_top_level ();
  import rv32v_types_pkg::*;
  import rv32i_types_pkg::*;

  parameter PERIOD = 20;

  logic CLK, nRST;
  vopm_t op;


  typedef struct packed {
    vopi_t funct6;
    logic vm;
    logic [4:0] rs2;
    logic [4:0] rs1;
    vfunct3_t funct3;
    logic [4:0] rd;
    opcode_t op;
  } vopi_ins;

  typedef struct packed {
    vopm_t funct6;
    logic vm;
    logic [4:0] rs2;
    logic [4:0] rs1;
    vfunct3_t funct3;
    logic [4:0] rd;
    opcode_t op;
  } vopm_ins;

  logic [31:0] xs1, xs2;
  logic scalar_hazard_if_ret;
  logic returnex;
  logic rd_WEN;
  logic [4:0] rd_sel;
  logic [31:0] rd_data;



  rv32v_fetch2_decode_if  fetch_decode_if();
  cache_model_if cif();
  rv32v_hazard_unit_if hu_if();
  prv_pipeline_if prv_if();

  rv32v_top_level      DUT (.*);


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
    @(posedge CLK);
    nRST = 1;
  endtask

  task load_reg_data;
    input logic [4:0] sel;
    input logic [127:0] data;
  // `ifdef TESTBENCH
    @(negedge CLK);
    DUT.reg_file.tb_ctrl = 1;
    DUT.reg_file.tb_sel = sel;
    DUT.reg_file.tb_data = data;
    @(posedge CLK);
    #(1);
    DUT.reg_file.tb_ctrl = 0;
  endtask

  task init();
    reset();
    prv_if.lmul    = LMUL2;
    prv_if.sew     = SEW32;
    prv_if.vtype     = {2'b0, LMUL1, SEW32};
    prv_if.vl      = 8;
    prv_if.vstart  = 0;
    prv_if.vlenb   = 16;
    prv_if.vill    = 0;
    xs1 = 32'hABCD;
    xs2 = 32'hDCBA;
    scalar_hazard_if_ret = 0;
    returnex = 0;
    fetch_decode_if.fault_insn = 0;
    fetch_decode_if.mal_insn = 0;
    cif.dhit = 0;
    cif.dmemload = 0;
    

  // rv32v_fetch2_decode_if.decode  fetch_decode_if,
  // cache_model_if.memory cif

  endtask


  bit [9:0] bitarray;
  int hexfile;
  bit [31:0] line;
  vopi_ins ins_i;
  vopm_ins ins_m;

  initial begin : MAIN
    fetch_decode_if.instr = 0;
    init();
    load_reg_data(0, '1);
    load_reg_data(1, {32'h4, 32'd3, 32'd2, 32'd1});
    load_reg_data(2, {32'd3, 32'd2, 32'd1, 32'd0});
    @(posedge CLK);
    hexfile = $fopen("rv32v/tb/add.hex", "r");   
    
    while (!$feof(hexfile)) begin 
        $fscanf(hexfile,"%h\n",line); 
        $write("Line Value: %x\n", line);
        ins_i = vopi_ins'(line);
        ins_m = vopm_ins'(line);
        fetch_decode_if.instr = line;
        @(posedge CLK); //wait some time as needed.
        while(hu_if.busy_dec) @(posedge CLK); //wait some time as needed.
        // while (hu_if.busy_dec | hu_if.busy_ex)  begin @(posedge CLK) end; 
    end 
    //once reading and writing is finished, close the file.
    $fclose(hexfile);
    #(10)
    
    // op = VWMACCSU;
    // if (op inside {VWMACCSU, VWMACCUS}) $write("\n\n\n\nSUCCESS\n\n\n\n");

    $finish;
  end : MAIN
endmodule

