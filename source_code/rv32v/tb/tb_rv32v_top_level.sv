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

import rv32v_types_pkg::*;
import rv32i_types_pkg::*;

//have all instructions inherit from one instruction parent class
//have an array of instructions, these contain the values of xs1, xs2

class RegReg;
  logic [31:0] instr;

  function new(logic [5:0] funct6, bit vm, logic [4:0] vs2, logic [4:0] vs1, vfunct3_t funct3, logic [4:0] vd);
    this.instr = {funct6, vm, vs2, vs1, funct3, vd, VECTOR};
  endfunction;

endclass

class Vsetvl;
  logic [31:0] instr;

  function new(logic [4:0] rs2, logic [4:0] rs1, logic [4:0] rd);
    this.instr = {7'b1000000,  rs2, rs1, 3'b111, rd, VECTOR};
  endfunction;

endclass

class Vsetvli;
  logic [31:0] instr;
  bit vma;
  bit vta;

  function new(sew_t sew, vlmul_t lmul, logic [4:0] rs1, logic [4:0] rd);
    vma = 0;
    vta = 0;
    this.instr = {1'b0, 5'd0, vma, vta, sew, lmul, rs1, 3'b111, rd, VECTOR};
  endfunction;

endclass

class Vsetivli;
  logic [31:0] instr;
  bit vma;
  bit vta;

  function new(sew_t sew, vlmul_t lmul, logic [4:0] imm5, logic [4:0] rd);
    vma = 0;
    vta = 0;
    this.instr = {2'b11, 4'd0, vma, vta, sew, lmul, imm5, 3'b111, rd, VECTOR};
  endfunction;

endclass

// `include "instruction.svh"

module tb_rv32v_top_level ();

  parameter PERIOD = 20;
  parameter MASKED = 0;
  parameter UNMASKED = 1;
  parameter VL = 16;

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
  instr_list_t instr_mem [];
  int testnum;



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
    // xs1 = VL;
    xs2 = {24'd0, 2'd0, SEW32, LMUL2}; //if vsetvl
    scalar_hazard_if_ret = 0;
    returnex = 0;
    fetch_decode_if.fault_insn = 0;
    fetch_decode_if.mal_insn = 0;
    cif.dhit = 0;
    cif.dmemload = 0;

    load_reg_data(0, {{30{4'hF}}, 8'b1111_1111});
    // load_reg_data(1, {128'd0});
    // load_reg_data(2, {128'd0});
    load_reg_data(4, {16'hf, 16'he, 16'hd, 16'hc, 16'hb, 16'ha, 16'h9, 16'h8});
    load_reg_data(3, {16'h7, 16'h6, 16'h5, 16'h4, 16'h3, 16'd2, 16'd1, 16'h0});
    // load_reg_data(3, {32'h7, 32'h3,  32'hFFFF,  32'h8000_0002});
    // load_reg_data(4, {32'h1F,  32'hF,  32'hF,  32'hB});
    // load_reg_data(1, {{8{16'hFF}}});
    load_reg_data(2, {{32{4'hF}}});
    load_reg_data(1, {{8{16'h5555}}});
    load_reg_data(3, {{4{32'h7000_0000}}});
    // load_reg_data(3, {{8{16'haaa}}});
    // load_reg_data(1, {16'h7, 16'd6, 16'd5, 16'd4, 16'h3, 16'd2, 16'd1, 16'hFFF1});
    // load_reg_data(2, {16'hF, 16'hE, 16'hD, 16'hC, 16'hB, 16'hA, 16'h9, 16'h8});
    // load_reg_data(3, {16'h7, 16'd6, 16'd5, 16'd4, 16'h3, 16'd2, 16'd0, 16'hFFF2});
    // load_reg_data(4, {16'hF, 16'hE, 16'hD, 16'hC, 16'hB, 16'hA, 16'h9, 16'h8});

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

  task read_init_file;
    input string filename;
    output int instr_mem [][];
    int line_buffer [];
    int i;
    int hexfile;
    bit [31:0] line;

    hexfile = $fopen(filename, "r");   
    instr_mem = new [0];
    line_buffer = new [2];
    i = 0;
    while (!$feof(hexfile)) begin 
      $fscanf(hexfile,"%h\n",line); 
      line_buffer[0] = line;
      $fscanf(hexfile,"%h\n",line); 
      line_buffer[1] = line;
      
      instr_mem = new [i + 1] (instr_mem);
      instr_mem[i] = line_buffer;
      i = i + 1;
      // #(1);
    end
    $fclose(hexfile);
    // return instr_mem;

  endtask


  //Add test case (list of instructions in hex) to the list of test cases
  task add_test_case;

    input int line_buffer [];

    instr_mem = new [instr_mem.size() + 1] (instr_mem);
    instr_mem[instr_mem.size() - 1] = line_buffer;

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

    logic [4:0] vs1, vs2, vd;

    if (lmul == LMUL1) begin vs1 = 1; vs2 = 2; vd = 3; end
    else if (lmul == LMUL2) begin vs1 = 1; vs2 = 3; vd = 5;  end 
    else if (lmul == LMUL4) begin vs1 = 1; vs2 = 5; vd = 9;  end 
    else if (lmul == LMUL8) begin vs1 = 1; vs2 = 9; vd = 15; end 

    xs1 = vl;

    v = new(sew, lmul, 1, 2);
    r = new(funct6, vm, vs2, vs1, funct3, vd);

    return {v.instr, r.instr};
  
  endfunction

  
  function instr_list_t new_config_vop_reg_case(
     sew_t sew,
     vlmul_t lmul,
     int vl,
     vopm_t funct6,
     vfunct3_t funct3,
     bit vm, 
     logic [4:0] vs1
  );
    // output int [] out;

    Vsetvli v;
    RegReg r;

    logic [4:0]  vs2, vd;

    if (lmul == LMUL1) begin  vs2 = 2; vd = 3; end
    else if (lmul == LMUL2) begin vs2 = 3; vd = 5;  end 
    else if (lmul == LMUL4) begin vs2 = 5; vd = 9;  end 
    else if (lmul == LMUL8) begin vs2 = 9; vd = 15; end 

    xs1 = vl;

    v = new(sew, lmul, 1, 2);
    r = new(funct6, vm, vs2, vs1, funct3, vd);

    return {v.instr, r.instr};
  
  endfunction

  task check_outputs;
    input logic [255:0] expected;
    // $info("%d, %d, %d, %d", DUT.reg_file.registers[6][15:12], DUT.reg_file.registers[6][11:8], DUT.reg_file.registers[6][7:4], DUT.reg_file.registers[6][3:0]);
    // $display("%d, %d, %d, %d", DUT.reg_file.registers[1][15:12], DUT.reg_file.registers[1][11:8], DUT.reg_file.registers[1][7:4], DUT.reg_file.registers[1][3:0]);
    if (expected == {DUT.reg_file.registers[6], DUT.reg_file.registers[5]}) $display("correct");
      // $display("");
  endtask

  int hexfile;
  bit [31:0] line;
  vopi_ins ins_i;
  vopm_ins ins_m;
  vop_cfg ins_c;
  int i, old_i;
  RegReg rri;



  initial begin : MAIN
    testnum = 0;
    update = 0;
    fetch_decode_if.instr = 0;
    // read_init_file("rv32v/tb/init.hex", instr_mem);
    // add_test_case({32'h0910F2D7, 32'h0011C2D7});
    // rri = new(VADD, 1'b0, 1, 3, OPIVV, 5);
    // $display("%x", rri.instr);
    add_test_case(new_config_vop_case(SEW32, LMUL2, 8,  VADD, OPIVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW32, LMUL2, 8,  VRSUB, OPIVI, UNMASKED));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16,  VMUNARY0, OPMVV, UNMASKED));
    add_test_case(new_config_vop_reg_case(SEW16, LMUL2, 16, VMUNARY0, OPMVV, UNMASKED, VMSBF));
    // add_test_case(new_config_vop_reg_case(SEW32, LMUL2, 8,  VXUNARY0, OPMVV, UNMASKED, VZEXT_VF4));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16, VWSUBU_W, OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16, VWSUB_W,  OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16, VWADD_W,  OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW32, LMUL2, VDIV, OPMVV, UNMASKED));


    init();

    @(posedge CLK);
 
    for (i = 0; i < instr_mem.size(); i++) begin

      //these are just for visualization

      #(PERIOD * 3);


      //Do one test case
      for (int j = 0; j < instr_mem[i].size(); j++) begin 
        // instr_mem[i][j]
        ins_i = vopi_ins'(instr_mem[i][j]);
        ins_m = vopm_ins'(instr_mem[i][j]);
        ins_c = vop_cfg'(instr_mem[i][j]);
        fetch_decode_if.instr = instr_mem[i][j];
        fetch_decode_if.tb_line_num = j;
        do begin
          if (hu_if.csr_update) begin j = DUT.memory_writeback_if.tb_line_num; end
          @(posedge CLK); //wait some time as needed.
        end while(hu_if.busy_dec);      
        @(posedge CLK);
        // while(hu_if.busy_dec) @(posedge CLK);
      end
      repeat (1) @(posedge CLK);
      #(1);
      check_outputs({32'hAAAA, 32'hc, 32'ha, 32'h8, 32'h6, 32'h4, 32'h2, 32'h0});
      repeat (2) @(posedge CLK);
        // testcase 
      init();
      testnum++;
    end
      
    #(PERIOD * 3);
    display_reg_file();
    // op = VWMACCSU;
    // if (op inside {VWMACCSU, VWMACCUS}) $write("\n\n\n\nSUCCESS\n\n\n\n");

    $finish;
  end : MAIN
endmodule

