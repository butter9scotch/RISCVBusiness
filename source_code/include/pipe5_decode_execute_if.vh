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
*   Filename:     tspp_fetch_execute_if.vh
*   
*   Created by:   Jacob R. Stevens	
*   Email:        steven69@purdue.edu
*   Date Created: 06/01/2016
*   Description:  Interface between the fetch and execute pipeline stages
*/

`ifndef PIPE5_DECODE_EXECUTE_IF_VH
`define PIPE5_DECODE_EXECUTE_IF_VH

interface pipe5_decode_execute_if;
  import rv32i_types_pkg::*;
  import rv32m_pkg::*;
  import alu_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  word_t       port_a;
  word_t       port_b;
  word_t       reg_file_wdata;
  word_t       store_wdata;
  word_t       rs1_data;
  word_t       rs2_data;
  word_t       br_imm_sb;
  logic  [4:0] reg_rs1, reg_rs2, reg_rd;
  word_t       j_base;
  word_t       j_offset;
  word_t       pc;
  word_t       pc4;
  word_t       csr_imm_value;
  word_t       instr;
  aluop_t      aluop;
  load_t       load_type;
  branch_t     br_branch_type;
  opcode_t     opcode;
  csr_addr_t   csr_addr;
  logic [3:0]  byte_en_temp;
  logic [2:0]  w_sel;
  logic [1:0]  alu_a_sel, alu_b_sel;
  logic        wen;
  logic        dwen;
  logic        dren;
  logic        jump_instr;
  logic        branch_instr;
  logic        prediction;
  logic        halt_instr;
  logic        csr_instr;
  logic        lui_instr;
  logic        j_sel;
  logic        ifence;
  logic        csr_swap, csr_set, csr_clr;
  logic        csr_imm;
  logic        illegal_insn, ecall_insn, ret_insn, breakpoint;
  logic        token;
  logic        mal_insn;
  logic        fault_insn;
  logic [2:0]  funct3;
  logic [11:0] funct12;
  logic [11:0] imm_I, imm_S;
  logic [12:0] imm_SB;
  logic        instr_30;
  logic        wfi;
  word_t       imm_UJ_ext;
  word_t       imm_U;
  scalar_fu_t  sfu_type;
  sign_type_t  sign_type;
  logic high_low_sel;
  logic div_type;


  modport decode(
      output port_a, port_b, aluop, 
             reg_rs1, reg_rs2, reg_rd, alu_a_sel, alu_b_sel,
             reg_file_wdata, w_sel, wen,
             dwen, dren, store_wdata, load_type, byte_en_temp,
             jump_instr, j_base, j_offset, j_sel,
             rs1_data, rs2_data, br_imm_sb, br_branch_type,
             branch_instr, prediction, pc, pc4,
             ifence,opcode,halt_instr, lui_instr, 
             csr_instr, csr_swap, csr_set, csr_clr, csr_imm, 
             csr_addr, csr_imm_value, instr,
             illegal_insn,ecall_insn, breakpoint, ret_insn, token,
             mal_insn, fault_insn,
             funct3, funct12, imm_I, imm_S, imm_UJ_ext,
             imm_SB, imm_U, instr_30, wfi, sfu_type, sign_type, 
             high_low_sel, div_type
  );

  modport execute(
      input  port_a, port_b, aluop,  
             reg_rs1, reg_rs2, reg_rd, alu_a_sel, alu_b_sel,
             reg_file_wdata, w_sel, wen,
             dwen, dren, store_wdata, load_type, byte_en_temp,
             jump_instr, j_base, j_offset, j_sel,
             rs1_data, rs2_data, br_imm_sb, br_branch_type,
             branch_instr, prediction,pc, pc4,
             ifence,opcode,
             halt_instr, lui_instr,
             csr_instr, csr_swap, csr_set, csr_clr, csr_imm, 
             csr_addr, csr_imm_value, instr,
             illegal_insn,ecall_insn, breakpoint, ret_insn, token,
             mal_insn, fault_insn, 
             funct3, funct12, imm_I, imm_S, imm_UJ_ext,
             imm_SB, imm_U, instr_30, wfi, sfu_type, sign_type, 
             high_low_sel, div_type
  );

endinterface
`endif
