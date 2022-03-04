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
`ifndef PIPE5_MEM_WRITEBACK_IF_VH
`define PIPE5_MEM_WRITEBACK_IF_VH

interface pipe5_mem_writeback_if;
  import rv32i_types_pkg::*;
 
  word_t       reg_file_wdata;
  word_t       pc;
  word_t       pc4;
  word_t       dload_ext;
  word_t       alu_port_out;
  word_t       csr_rdata;
  opcode_t     opcode;
  logic [2:0]  w_sel;
  logic        wen;
  logic        halt_instr;
  logic        csr_instr;
  logic [2:0]  funct3;
  logic [11:0] funct12;
  logic [11:0] imm_I, imm_S;
  logic [12:0] imm_SB;
  logic        instr_30;
  word_t       imm_UJ_ext;
  word_t       imm_U;
  logic  [4:0] rs1, rs2, reg_rd;
  word_t       instr;

  //floating point signals
  logic [4:0] f_reg_rs1, f_reg_rs2, f_reg_rd;
  logic [2:0] f_wsel;
  logic f_wen;

  logic [4:0] fpu_flags;
  word_t f_wdata, fpu_out;


  modport memory(
     output  reg_file_wdata, w_sel, wen, reg_rd, alu_port_out, dload_ext,
             pc, pc4,opcode,
             halt_instr, 
             csr_instr, csr_rdata,
             funct3, funct12, imm_I, imm_S, imm_UJ_ext,
             imm_SB, imm_U, instr_30, rs1, rs2, instr,
             f_reg_rs1, f_reg_rs2, f_reg_rd, f_wsel, f_wen,
             f_wdata, fpu_out, fpu_flags
  );

  modport writeback(
     input   reg_file_wdata, w_sel, wen, reg_rd, alu_port_out, dload_ext,
             pc, pc4,opcode,
             halt_instr, 
             csr_instr, csr_rdata,
             funct3, funct12, imm_I, imm_S, imm_UJ_ext,
             imm_SB, imm_U, instr_30, rs1, rs2, instr,
             f_reg_rs1, f_reg_rs2, f_reg_rd, f_wsel, f_wen,
             f_wdata, fpu_out, fpu_flags
  );

endinterface
`endif


