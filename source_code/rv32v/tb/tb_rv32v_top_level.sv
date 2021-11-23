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
// `include "config_test.svh"



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
  logic rd_wen;
  logic [4:0] rd_sel;
  logic [31:0] rd_data;



  rv32v_fetch2_decode_if  fetch_decode_if();
  cache_model_if cif();
  rv32v_hazard_unit_if hu_if();
  prv_pipeline_if prv_if();
  core_interrupt_if interrupt_if();


  rv32v_top_level      DUT (.*);
  priv_wrapper PRIV (.prv_pipe_if(prv_if), .*);
  logic update;



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
    // prv_if.lmul    = LMUL2;
    // prv_if.sew     = SEW32;
    // prv_if.vtype     = {2'b0, LMUL1, SEW32};
    // prv_if.vl      = 8;
    // prv_if.vstart  = 0;
    // prv_if.vlenb   = 16;
    xs1 = 32'd16;
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

  task display_reg;
    input logic [4:0] rs;

    automatic int i;
    automatic int sum;
    sum = 0;
    for (i = VLENB - 1; i >= 0; i--) begin
      sum += DUT.reg_file.registers[rs][i];
    end
    if (sum != 0) begin
      $write("register[%d]: ", rs);
      for (i = VLENB - 1; i >= 0; i--) begin
        if (i % 4 == 3 && (i != 15)) begin
          $write(" --- [%x]", DUT.reg_file.registers[rs][i]);
        end else begin
          $write(" [%x]", DUT.reg_file.registers[rs][i]);
        end
      end
      $write("\n");
    end
    // $display("[%x] [%x] [%x] [%x] [%x] [%x] [%x] [%x]", DUT.registers[vs1][7], DUT.registers[vs1][6],DUT.registers[vs1][5],DUT.registers[vs1][4],DUT.registers[vs1][3],DUT.registers[vs1][2],DUT.registers[vs1][1],DUT.registers[vs1][0]);
    // #2;
  endtask

  task display_reg_file;
    automatic int i;
    $write("\n");
    for (i = 0; i < 32; i++) begin
      display_reg(i);
    end
    $write("\n");

  endtask

  task display_vars;
  //   $display("fetch stage: %h", DUT.fetch_decode_if.decode.instr);
  //   // $display("avl:   %h", DUT.execute_memory_if.next_avl_csr);
  endtask


  always @(posedge PRIV.priv_block_i.csr_rfile_i.vtype.lmul) begin
    display_vars();
  end

  // always @(posedge DUT.fetch_decode_if.decode.instr) begin
  //   $display("instr: %h", DUT.fetch_decode_if.instr);
  // end

  // always @(negedge hu_if.decode.busy_dec) begin
  //   $display("DECODE CHANGED");
  // end

  // always @(update) begin
  //   if (~hu_if.busy_dec) $info("busy_de = %d", hu_if.busy_dec);
  // end

  task build_instr_mem;
    input string filename;
    output int instr_mem [];
    int line_buffer [];
    int i;
    int hexfile;
    bit [31:0] line;

    hexfile = $fopen("rv32v/tb/config.hex", "r");   
    instr_mem = new [0];
    line_buffer = new [2];
    i = 0;
    while (!$feof(hexfile)) begin 
      $fscanf(hexfile,"%h\n",line); 
      // line_buffer[0] = line;
      // $fscanf(hexfile,"%h\n",line); 
      // line_buffer[1] = line;
      
      instr_mem = new [i + 1] (instr_mem);
      instr_mem[i] = line;
      i = i + 1;
      #(1);
    end
    $fclose(hexfile);
    // return instr_mem;

  endtask

  task execute_test;
  endtask

  int hexfile;
  bit [31:0] line;
  vopi_ins ins_i;
  vopm_ins ins_m;
  vop_cfg ins_c;
  int instr_mem [];
  int i, old_i;

  initial begin : MAIN
    update = 0;
    fetch_decode_if.instr = 0;
    init();
    build_instr_mem("", instr_mem);
    load_reg_data(0, '1);
    load_reg_data(1, {32'h3, 32'd2, 32'd1, 32'd0});
    load_reg_data(2, {32'h7, 32'd6, 32'd5, 32'd4});
    load_reg_data(3, {32'd3, 32'd2, 32'd1, 32'd0});
    load_reg_data(4, {32'd7, 32'd6, 32'd5, 32'd4});
    @(posedge CLK);
    // hexfile = $fopen("rv32v/tb/config.hex", "r");   
    // i = 1;
    // while (!$feof(hexfile)) begin 
    //     $fscanf(hexfile,"%h\n",line); 
    //     $write("Line Value: %x\n", line);
    //     ins_i = vopi_ins'(line);
    //     ins_m = vopm_ins'(line);
    //     fetch_decode_if.instr = line;
    //     // fetch_decode_if.tb_instr_num = line;
    //     @(posedge CLK); //wait some time as needed.
    //     // display_vars();
    //     while(hu_if.busy_dec) @(posedge CLK); //wait some time as needed.
    //     // while (hu_if.busy_dec | hu_if.busy_ex)  begin @(posedge CLK) end; 
    // end 
    // //once reading and writing is finished, close the file.
    // $fclose(hexfile);
    // #(10)
    for (i = 0; i < instr_mem.size(); i++) begin
        line = instr_mem[i];
        // $write("Line Value: %x\n", line);
        ins_i = vopi_ins'(line);
        ins_m = vopm_ins'(line);
        ins_c = vop_cfg'(line);
        $info("line[%1d] is %1d", i, instr_mem[i]);
        fetch_decode_if.instr = line;
        fetch_decode_if.tb_line_num = i; 

        do begin
          if (hu_if.csr_update) begin
            old_i = i;
            i = DUT.memory_writeback_if.tb_line_num;
            $info("%d --> %d", old_i, i);
          end
          update = ~update;
          @(posedge CLK); //wait some time as needed.
            //  fetch_decode_if.instr = 0;

        end while(hu_if.busy_dec);
    end
      
    #(PERIOD * 3);
    display_reg_file();
    // op = VWMACCSU;
    // if (op inside {VWMACCSU, VWMACCUS}) $write("\n\n\n\nSUCCESS\n\n\n\n");

    $finish;
  end : MAIN
endmodule

