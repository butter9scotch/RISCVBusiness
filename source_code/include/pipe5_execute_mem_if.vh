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

`ifndef PIPE5_EXECUTE_MEM_IF_VH
`define PIPE5_EXECUTE_MEM_IF_VH

interface pipe5_execute_mem_if;
  import rv32i_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;
 
  word_t       reg_file_wdata;
  word_t       store_wdata;
  word_t       alu_port_out;
  word_t       memory_addr;
  word_t       pc;
  word_t       pc4;
  word_t       br_resolved_addr;
  word_t       jump_addr;
  word_t       csr_wdata;
  load_t       load_type;
  word_t       instr;
  opcode_t     opcode;
  csr_addr_t   csr_addr;
  logic [3:0]  byte_en_temp;
  logic [2:0]  w_sel;
  logic        wen;
  logic        dwen;
  logic        dren;
  logic        jump_instr;
  logic        branch_instr;
  logic        halt_instr;
  logic        csr_instr;
  logic        lui_instr;
  logic        ifence;
  logic        branch_taken;
  logic        csr_swap, csr_set, csr_clr;
  logic        illegal_insn, ecall_insn, ret_insn, breakpoint;
  logic        token;
  logic        mal_insn;
  logic        fault_insn;
  logic        intr_seen;
  logic [2:0]  funct3;
  logic [11:0] funct12;
  logic [11:0] imm_I, imm_S;
  logic [12:0] imm_SB;
  logic        instr_30;
  word_t       imm_UJ_ext;
  word_t       imm_U;
  logic  [4:0] rs1, rs2, reg_rd;
  logic        wfi;
  logic        prediction;

  //floating point signals
  logic [4:0] f_reg_rs1, f_reg_rs2, f_reg_rd, fpu_flags;
  logic [2:0] f_wsel;
  logic f_wen;

  word_t f_wdata, f_store_wdata, fpu_out;

  modport execute(
     output  reg_file_wdata, w_sel, wen, alu_port_out, pc, pc4, reg_rd,
             dwen, dren, store_wdata, load_type, memory_addr,byte_en_temp,
             jump_instr,lui_instr,jump_addr, 
             branch_instr, prediction, br_resolved_addr, branch_taken,
             ifence,opcode,
             halt_instr, 
             csr_instr, csr_swap, csr_set, csr_clr, csr_wdata,
             csr_addr, instr,
             illegal_insn,ecall_insn, breakpoint, ret_insn,token,
             mal_insn, fault_insn, intr_seen,
             funct3, funct12, imm_I, imm_S, imm_UJ_ext,
             imm_SB, imm_U, instr_30, rs1, rs2, wfi,
             f_reg_rs1, f_reg_rs2, f_reg_rd, f_wsel, f_wen,
             f_wdata, f_store_wdata, fpu_out, fpu_flags
  );

  modport memory(
     input   reg_file_wdata, w_sel, wen, alu_port_out, pc, pc4, reg_rd,
             dwen, dren, store_wdata, load_type, memory_addr, byte_en_temp,
             jump_instr, lui_instr, jump_addr,
             branch_instr, prediction,br_resolved_addr, branch_taken,
             ifence,opcode,
             halt_instr, 
             csr_instr, csr_swap, csr_set, csr_clr, csr_wdata, 
             csr_addr, instr,
             illegal_insn,ecall_insn, breakpoint, ret_insn, token,
             mal_insn, fault_insn,intr_seen,
             funct3, funct12, imm_I, imm_S, imm_UJ_ext,
             imm_SB, imm_U, instr_30, rs1, rs2, wfi,
             f_reg_rs1, f_reg_rs2, f_reg_rd, f_wsel, f_wen,
             f_wdata, f_store_wdata, fpu_out, fpu_flags
  );

endinterface
`endif

