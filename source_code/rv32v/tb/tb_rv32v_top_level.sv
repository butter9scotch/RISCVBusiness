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
// `include "rvv_decoder.sv"
`include "rv32v_fetch2_decode_if.vh"
`include "rv32v_decode_execute_if.vh"
`include "rv32v_reg_file_if.vh"
`include "rv32v_hazard_unit_if.vh"
`include "prv_pipeline_if.vh"
`include "rv32v_top_level_if.vh"
`include "instruction.svh"
// `include "rvv_decoder.svh"
// `include "config_test.svh"

import rv32i_types_pkg::*;
// import rv32i_types_pkg::*;

//have all instructions inherit from one instruction parent class
//have an array of instructions, these contain the values of xs1, xs2


module tb_rv32v_top_level ();

  parameter PERIOD = 20;
  parameter MASKED = 0;
  parameter UNMASKED = 1;
  parameter VL = 16;
  parameter LMUL = 1;

  logic CLK, nRST;
  vopm_t op;

  typedef int instr_list_t[];

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

  int instr_idx;



  // Outputs to the DUT
  //logic [31:0] xs1, xs2;
  assign top_if.xs1 = xs1;
  assign top_if.xs2 = xs2;
  //logic scalar_hazard_if_ret;
  assign top_if.scalar_hazard_if_ret = scalar_hazard_if_ret;
  //logic returnex;
  assign top_if.returnex = returnex;



  rv32v_fetch2_decode_if  fetch_decode_if();
  cache_model_if cif();
  rv32v_hazard_unit_if hu_if();
  prv_pipeline_if prv_if();
  core_interrupt_if interrupt_if();
  rv32v_top_level_if top_if();


  rv32v_top_level      DUT (.*);
  priv_wrapper PRIV (.prv_pipe_if(prv_if), .*);



  initial begin : CLK_INIT
    CLK = 1'b0;
    nRST = 1;
  end : CLK_INIT

  always begin : CLK_GEN
    #(PERIOD/2) CLK = ~CLK;
  end : CLK_GEN
 
  task reset;
    @(negedge CLK);
    fetch_decode_if.tb_line_num = 0;
    fetch_decode_if.instr = 0;
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
    // xs1 = VL;
    xs2 = {24'd0, 2'd0, SEW32, LMUL2}; //if vsetvl
    scalar_hazard_if_ret = 0;
    returnex = 0;
    fetch_decode_if.fault_insn = 0;
    fetch_decode_if.mal_insn = 0;
    cif.dhit = 0;
    cif.dmemload = 0;

  endtask

  task display_reg;
    input logic [4:0] rs;

    automatic int i;
    automatic int sum;
    sum = 0;
    for (i = VLENB - 1; i >= 0; i--) begin
      sum |= DUT.reg_file.registers[rs][i];
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
    
  // Run new testcase
  task add_test_case;

    input int line_buffer [];
    input logic [31:0]  xs1_val;
    input logic [127:0] data0 [];
    input logic [127:0] data1 [];
    input logic [127:0] data2 [];
    input logic [127:0] data3 [];
    logic [127:0] actual;

    instr_list_t instr_mem;
    vopi_ins ins_i;
    vopm_ins ins_m;
    vop_cfg ins_c;
    vop_decoded_t op;
    int i;
    instr_idx = 0;
    instr_mem = line_buffer;
    init();

    
    for (i = 0; i < data0.size(); i++) begin
      load_reg_data(i, data0[i]);
    end
    for (i = 0; i < data1.size(); i++)begin
      load_reg_data(i + data0.size(), data1[i]); 
    end
    for (i = 0; i < data2.size(); i++)begin
      load_reg_data(i + data0.size() + data1.size(), data2[i]); 
    end
    for (i = 0; i < data3.size(); i++) begin
      load_reg_data(i + data0.size() + data1.size() + data2.size(), data3[i]); 
    end


    @(posedge CLK);
    #(PERIOD * 3);
    //Do one test case
    for (instr_idx = 0; instr_idx < line_buffer.size(); instr_idx++) begin 
      ins_i  = vopi_ins'(line_buffer[instr_idx]);
      ins_m  = vopm_ins'(line_buffer[instr_idx]);
      ins_c = vop_cfg'(line_buffer[instr_idx]);
      fetch_decode_if.instr = line_buffer[instr_idx];
      fetch_decode_if.tb_line_num = instr_idx;
      do begin
        if (instr_idx == 1) xs1 = xs1_val;
        if (hu_if.csr_update) begin instr_idx = DUT.memory_writeback_if.tb_line_num; end
        // $info("inside wait, csr_update: %d, tb_line_num: %d", );
        @(posedge CLK); 
        #(1);
      end while(hu_if.busy_dec);      
      @(posedge CLK);
    end

    #(PERIOD * 3);
    
    // op = decode(line_buffer[1]);
    // actual = DUT.reg_file.registers[3][15:0];
    display_reg_file();
    // checker(op, data0, data1, data2, data3, actual);
      

  endtask




  function instr_list_t new_config_vop_case(
     sew_t sew,
     vlmul_t lmul,
     int vl,
     vopi_t funct6,
     vfunct3_t funct3,
     bit vm
  );
    // output int [] out;

    Vsetvli v;
    RegReg r;
    RegReg a;

    logic [4:0] vs1, vs2, vd;

    // LMUL = lmul;

    if (lmul == LMUL1) begin vs1 = 1; vs2 = 2; vd = 3; end
    else if (lmul == LMUL2) begin vs1 = 1; vs2 = 3; vd = 5;  end 
    else if (lmul == LMUL4) begin vs1 = 1; vs2 = 5; vd = 9;  end 
    else if (lmul == LMUL8) begin vs1 = 1; vs2 = 9; vd = 17; end 

    xs1 = vl;

    v = new(sew, lmul, 1, 2);
    r = new(funct6, vm, vs2, vs1, funct3, vd);
    a = new(VADD, 1, 31, 0, OPIVI, 31);

    return {v.instr, r.instr, a.instr};
    // return {v.instr, r.instr};
  
  endfunction

  
  function instr_list_t new_config_vop_reg_case(
     sew_t sew,
     vlmul_t lmul,
     int vl,
     vopm_t funct6,
     vfunct3_t funct3,
     bit vm, 
     logic [4:0] vs1, 
     logic [4:0] vs2
  );
    // output int [] out;

    Vsetvli v;
    RegReg r;
    RegReg a;


    logic [4:0]   vd;

    if (lmul == LMUL1) begin  vd = 3; end
    else if (lmul == LMUL2) begin vd = 5;  end 
    else if (lmul == LMUL4) begin vd = 9;  end 
    else if (lmul == LMUL8) begin vd = 17; end 

    xs1 = vl;

    v = new(sew, lmul, 1, 2);
    r = new(funct6, vm, vs2, vs1, funct3, vd);
    a = new(VADD, 1, 31, 0, OPIVI, 31);


    // return {v.instr, r.instr};
    return {v.instr, r.instr, a.instr};

  
  endfunction

  task check_outputs;
    input logic [255:0] expected;
    // $info("%d, %d, %d, %d", DUT.reg_file.registers[6][15:12], DUT.reg_file.registers[6][11:8], DUT.reg_file.registers[6][7:4], DUT.reg_file.registers[6][3:0]);
    // $display("%d, %d, %d, %d", DUT.reg_file.registers[1][15:12], DUT.reg_file.registers[1][11:8], DUT.reg_file.registers[1][7:4], DUT.reg_file.registers[1][3:0]);
    if (expected == {DUT.reg_file.registers[6], DUT.reg_file.registers[5]}) $display("correct");
      // $display("");
  endtask

  bit [31:0] line;
  // vopi_ins ins_i;
  // vopm_ins ins_m;
  // vop_cfg ins_c;
  int i, old_i;
  RegReg rri;



  initial begin : MAIN
    fetch_decode_if.instr = 0;

    // This is the new test case task, I'm not sure if it's that good. The only thing
    // that changed is the way you load the initial register values into the register
    // file. It's now dynamic arrays of 128 bit registers, so you can initialize 
    // as many registers as you want. 
    add_test_case(new_config_vop_case(SEW16, LMUL2, 8, VSLIDEDOWN, OPIVX, UNMASKED), 
      32'd2, //value of xs1
      '{ //v0
        {32{4'hF}}
        },
      '{ //vs1
        {16'd0, 16'd1, 16'd2, 16'd3, 16'd0, 16'd1, 16'd2, 16'd3}, 
        {32'd0, 32'd1, 32'd2, 32'd3}
        }, 
      '{ //vs2
        {32'd0, 32'd1, 32'd2, 32'd3}, 
        {32'd4, 32'd5, 32'd6, 32'd7}
        }, 
      '{ //vs3
        128'd0
        }
    );



    // op = VWMACCSU;
    // if (op inside {VWMACCSU, VWMACCUS}) $write("\n\n\n\nSUCCESS\n\n\n\n");

    $finish;
  end : MAIN
endmodule

