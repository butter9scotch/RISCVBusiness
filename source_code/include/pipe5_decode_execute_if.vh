// /*
// *   Copyright 2016 Purdue University
// *   
// *   Licensed under the Apache License, Version 2.0 (the "License");
// *   you may not use this file except in compliance with the License.
// *   You may obtain a copy of the License at
// *   
// *       http://www.apache.org/licenses/LICENSE-2.0
// *   
// *   Unless required by applicable law or agreed to in writing, software
// *   distributed under the License is distributed on an "AS IS" BASIS,
// *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// *   See the License for the specific language governing permissions and
// *   limitations under the License.
// *   
// *   
// *   Filename:     tspp_fetch_execute_if.vh
// *   
// *   Created by:   Jacob R. Stevens	
// *   Email:        steven69@purdue.edu
// *   Date Created: 06/01/2016
// *   Description:  Interface between the fetch and execute pipeline stages
// */

// `ifndef PIPE5_DECODE_EXECUTE_IF_VH
// `define PIPE5_DECODE_EXECUTE_IF_VH

// interface pipe5_decode_execute_if();

//   import rv32i_types_pkg::*;
//   import rv32m_pkg::*;
//   import alu_types_pkg::*;
//   import machine_mode_types_1_11_pkg::*;

//   word_t port_a;
//   word_t port_b;
//   word_t reg_file_wdata;
//   word_t store_wdata;
//   word_t rs1_data;
//   word_t rs2_data;
//   word_t br_imm_sb;
//   word_t j_base;
//   word_t j_offset;
//   word_t pc;
//   word_t pc4;
//   word_t csr_imm_value;
//   word_t instr;
//   word_t imm_UJ_ext;
//   word_t imm_U;
//   logic [4:0] reg_rs1;
//   logic [4:0] reg_rs2;
//   logic [4:0] reg_rd;
//   aluop_t aluop;
//   load_t load_type;
//   branch_t br_branch_type;
//   opcode_t opcode;
//   csr_addr_t csr_addr;
//   scalar_fu_t sfu_type;
//   sign_type_t sign_type;
//   logic [11:0] imm_I;
//   logic [11:0] imm_S;
//   logic [11:0] funct12;
//   logic [12:0] imm_SB;
//   logic [3:0] byte_en_temp;
//   w_src_t w_src;
//   logic [2:0] funct3;
//   logic [1:0] alu_a_sel;
//   logic [1:0] alu_b_sel;
//   logic wen;
//   logic dwen;
//   logic dren;
//   logic jump_instr;
//   logic branch_instr;
//   logic prediction;
//   logic halt_instr;
//   logic csr_instr;
//   logic lui_instr;
//   logic j_sel;
//   logic ifence;
//   logic csr_swap;
//   logic csr_set;
//   logic csr_clr;
//   logic csr_imm;
//   logic illegal_insn;
//   logic ecall_insn;
//   logic ret_insn;
//   logic breakpoint;
//   logic token;
//   logic mal_insn;
//   logic fault_insn;
//   logic div_type;
//   logic instr_30;
//   logic wfi;
//   divide_struct_t      divide;
//   multiply_struct_t    multiply;
//   loadstore_struct_t   loadstore;
//   arith_struct_t       arith;
//   jump_struct_t        JUMP_STRUCT;
//   branch_struct_t      BRANCH_STRUCT;
//   csr_struct_t         CSR_STRUCT;
//   exception_struct_t   EXCEPTION_STRUCT;
//   logic high_low_sel;

//   modport decode (
//     output port_a, port_b, reg_file_wdata, store_wdata, rs1_data, rs2_data, 
//           br_imm_sb, j_base, j_offset, pc, pc4, csr_imm_value, 
//           instr, imm_UJ_ext, imm_U, reg_rs1, reg_rs2, reg_rd, 
//           aluop, load_type, br_branch_type, opcode, csr_addr, sfu_type, 
//           sign_type, imm_I, imm_S, funct12, imm_SB, byte_en_temp, 
//           w_src, funct3, alu_a_sel, alu_b_sel, wen, dwen, 
//           dren, jump_instr, branch_instr, prediction, halt_instr, csr_instr, 
//           lui_instr, j_sel, ifence, csr_swap, csr_set, csr_clr, 
//           csr_imm, illegal_insn, ecall_insn, ret_insn, breakpoint, token, 
//           mal_insn, fault_insn, div_type, instr_30, wfi, divide, 
//           multiply, loadstore
//   );

//   modport execute (
//     input port_a, port_b, reg_file_wdata, store_wdata, rs1_data, rs2_data, 
//           br_imm_sb, j_base, j_offset, pc, pc4, csr_imm_value, 
//           instr, imm_UJ_ext, imm_U, reg_rs1, reg_rs2, reg_rd, 
//           aluop, load_type, br_branch_type, opcode, csr_addr, sfu_type, 
//           sign_type, imm_I, imm_S, funct12, imm_SB, byte_en_temp, 
//           w_src, funct3, alu_a_sel, alu_b_sel, wen, dwen, 
//           dren, jump_instr, branch_instr, prediction, halt_instr, csr_instr, 
//           lui_instr, j_sel, ifence, csr_swap, csr_set, csr_clr, 
//           csr_imm, illegal_insn, ecall_insn, ret_insn, breakpoint, token, 
//           mal_insn, fault_insn, high_low_sel, div_type, instr_30, wfi, 
//           divide, multiply, loadstore
//   );

// endinterface

// `endif //PIPE5_DECODE_EXECUTE_IF_VH
