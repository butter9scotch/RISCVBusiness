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
*   Filename:     rv32i_types_pkg.sv
*
*   Created by:   Jacob R. Stevens
*   Email:        steven69@purdue.edu
*   Date Created: 06/01/2016
*   Description:  Package containing types used for a RV32I implementation
*/

`ifndef RV32I_TYPES_PKG_SV
`define RV32I_TYPES_PKG_SV

`include "machine_mode_types_1_11_pkg.sv"

package rv32i_types_pkg;
  // import alu_types_pkg::aluop_t;
  parameter WORD_SIZE = 32;
  parameter RAM_ADDR_SIZE = 32;
  parameter OP_W = 7;
  parameter BR_W = 3;
  parameter LD_W = 3;
  parameter SW_W = 3;
  parameter IMM_W = 3;
  parameter REG_W = 3;
  parameter NUM_CB_ENTRY = 16;

  typedef logic [WORD_SIZE-1:0] word_t;

  typedef enum logic [OP_W-1:0] {
    LUI       = 7'b0110111,
    AUIPC     = 7'b0010111,
    JAL       = 7'b1101111,
    JALR      = 7'b1100111,
    // All branching instructions share an opcode
    BRANCH    = 7'b1100011,
    // All load instructions share an opcode
    LOAD      = 7'b0000011,
    // All store instructions share an opcode
    STORE     = 7'b0100011,
    // All immediate ALU instructions share an opcode
    IMMED     = 7'b0010011,
    // All register-register instructions share an opcode
    REGREG    = 7'b0110011,
    // All system instructions share an opcode
    SYSTEM    = 7'b1110011,
    MISCMEM  = 7'b0001111
  } opcode_t;

  typedef enum logic [BR_W-1:0] {
    BEQ     = 3'b000,
    BNE     = 3'b001,
    BLT     = 3'b100,
    BGE     = 3'b101,
    BLTU    = 3'b110,
    BGEU    = 3'b111
  } branch_t;

  typedef enum logic [LD_W-1:0] {
    LB      = 3'b000,
    LH      = 3'b001,
    LW      = 3'b010,
    LBU     = 3'b100,
    LHU     = 3'b101
  } load_t;

  typedef enum logic [SW_W-1:0] {
    SB      = 3'b000,
    SH      = 3'b001,
    SW      = 3'b010
  } store_t;

  typedef enum logic [IMM_W-1:0] {
    ADDI    = 3'b000,
    SLTI    = 3'b010,
    SLTIU   = 3'b011,
    XORI    = 3'b100,
    ORI     = 3'b110,
    ANDI    = 3'b111,
    SLLI    = 3'b001,
    // Logical/Arithmetic based on bit 30 of instruction
    //    0   /    1
    SRI     = 3'b101
  } imm_t;

  typedef enum logic [REG_W-1:0] {
    // Add/Sub based on bit 30 of instruction
    //  0 / 1
    ADDSUB  = 3'b000,
    SLL     = 3'b001,
    SLT     = 3'b010,
    SLTU    = 3'b011,
    XOR     = 3'b100,
    // Logical/Arithmetic based on bit 30 of instruction
    //    0   /    1
    SR      = 3'b101,
    OR      = 3'b110,
    AND     = 3'b111
  } regreg_t;

  typedef enum logic [2:0] {
    // Non CSR contains ECALL, EBREAK, and xRET instructions
    // ECALL/EBREAK based on bit 20 of instruction
    //   0  /   1
    //   xRET based on bits 28 and 29 of instruction
    PRIV        = 3'b000,
    CSRRW       = 3'b001,
    CSRRS       = 3'b010,
    CSRRC       = 3'b011,
    CSRRWI      = 3'b101,
    CSRRSI      = 3'b110,
    CSRRCI      = 3'b111
  } rv32i_system_t;

  typedef enum logic [11:0] {
    ECALL   = 12'b0000000_00000,
    EBREAK  = 12'b0000000_00001,
    MRET    = 12'b0011000_00010,
    SRET    = 12'b0001000_00010,
    URET    = 12'b0000000_00010,
    WFI     = 12'b0001000_00101
  } priv_insn_t;

  typedef enum logic [2:0] {
    FENCE   = 3'b000,
    FENCEI  = 3'b001
  } rv32i_miscmem_t;

  typedef enum logic [3:0] {
    ALU_SLL   = 4'b0000,
    ALU_SRL   = 4'b0001,
    ALU_SRA   = 4'b0010,
    ALU_ADD   = 4'b0011,
    ALU_SUB   = 4'b0100,
    ALU_AND   = 4'b0101,
    ALU_OR    = 4'b0110,
    ALU_XOR   = 4'b0111,
    ALU_SLT   = 4'b1000,
    ALU_SLTU  = 4'b1001
  } aluop_t;

  typedef struct packed {
    logic [6:0] funct7;
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [4:0] rd;
    opcode_t    opcode;
  } rtype_t;

  typedef struct packed {
    logic [11:0]  imm11_00;
    logic [4:0]   rs1;
    logic [2:0]   funct3;
    logic [4:0]   rd;
    opcode_t      opcode;
  } itype_t;

  typedef struct packed {
    logic [6:0] imm11_05;
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [4:0] imm04_00;
    opcode_t    opcode;
  } stype_t;

  typedef struct packed {
    logic       imm12;
    logic [5:0] imm10_05;
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [2:0] funct3;
    logic [3:0] imm04_01;
    logic       imm11;
    opcode_t    opcode;
  } sbtype_t;

  typedef struct packed {
    logic [19:0]  imm31_12;
    logic [4:0]   rd;
    opcode_t      opcode;
  } utype_t;

  typedef struct packed {
    logic         imm20;
    logic [9:0]   imm10_01;
    logic         imm11;
    logic [7:0]   imm19_12;
    logic [4:0]   rd;
    opcode_t      opcode;
  } ujtype_t;

  typedef struct packed {
    logic [11:0]  csr;
    logic [4:0]   rs1_zimm;
    logic [2:0]   funct3;
    logic [4:0]   rd;
    opcode_t      opcode;
  } systype_t;

  typedef struct packed {
    logic         token;
    word_t        pc;
    word_t        pc4;
    word_t        instr;
    word_t        prediction;
  } fetch_ex_pipeline_reg_t;

  typedef enum logic[1:0] {
    ARITH_S,
    MUL_S,
    DIV_S,
    LOADSTORE_S
  } scalar_fu_t;

  typedef enum logic [1:0] {
    SIGNED          = 2'b11,
    SIGNED_UNSIGNED = 2'b01,
    UNSIGNED_SIGNED = 2'b10,
    UNSIGNED        = 2'b00
  } sign_type_t;

  typedef enum logic [2:0] {
    LOAD_SRC = 3'd0,
    JUMP_SRC = 3'd1,
    LUI_SRC  = 3'd2,
    ALU_SRC  = 3'd3,
    CSR      = 3'd4
  } w_src_t;

  typedef struct packed{
    word_t rs1_data;
    word_t rs2_data;
  } common_fu_io_t;

  /***** Control Signal Types for Functional Units *****/

  // TODO: needs the remaining signals for CSR and others
  typedef struct packed {

    aluop_t alu_op;
    w_src_t w_src;
    logic wen;
    logic [4:0] reg_rd;
    logic ready_a;
    logic [$clog2(NUM_CB_ENTRY)-1:0] index_a; 
  } arith_control_signals_t;

  typedef struct packed {
    logic ena;
    logic high_low_sel;
    sign_type_t is_signed;
    logic decode_done;
    logic wen;
    logic [4:0] reg_rd;
    logic ready_mu;
    logic [$clog2(NUM_CB_ENTRY)-1:0] index_mu; 
  } mult_control_signals_t;

  typedef struct packed {
    logic ena;
    logic div_type;
    logic is_signed;
    logic wen;
    logic [4:0] reg_rd;
    logic ready_du;
    logic [$clog2(NUM_CB_ENTRY)-1:0] index_du; 
  } div_control_signals_t;

  typedef struct packed {
    load_t load_type;
    logic byte_en;
    logic dren;
    logic dwen;
    opcode_t opcode;
    logic wen;
    logic [4:0] reg_rd;
    logic ready_ls;
    logic [$clog2(NUM_CB_ENTRY)-1:0] index_ls; 
  } lsu_control_signals_t;

  typedef struct packed {
    logic csr_instr;
    logic csr_swap;
    logic csr_clr;
    logic csr_set;
    machine_mode_types_1_11_pkg::csr_addr_t csr_addr;
    logic csr_imm;
    logic [31:0] csr_imm_value;
    logic instr_null;
  } csr_control_signals_t;

  typedef struct packed {
    branch_t branch_type;
    logic branch_instr;
    logic prediction;
  } branch_control_signals_t;

  typedef struct packed {
    logic jump_instr;
    word_t j_base;
    word_t j_offset;
    logic j_sel;
  } jump_control_signals_t;


  // do not use atm
  typedef struct packed {
    word_t w_data;
    logic [4:0] reg_rd;
    logic wen;
  } fu_out_t;

  typedef struct packed {
    logic [2:0] funct3;
    logic [11:0] funct12;
    logic [11:0] imm_S;
    logic [11:0] imm_I;
    word_t imm_U;
    logic [11:0] imm_UJ_ext;
    logic [12:0] imm_SB;
    logic instr_30;
    logic [4:0] reg_rs1;
    logic [4:0] reg_rs2;
    logic [4:0] reg_rd; 
    word_t instr;
    word_t pc;
    opcode_t opcode;
  } cpu_tracker_t;

  // TODO: add floating point control signals struct here

  typedef struct packed {
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic start_mu;
    logic high_low_sel;
    logic decode_done;
    logic wen;
    sign_type_t is_signed;
    logic [4:0] reg_rd;
  } multiply_struct_t;

  typedef struct packed {
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic start_div;
    logic div_type;
    logic is_signed_div;
    logic wen;
    logic [4:0] reg_rd;
  } divide_struct_t;

  typedef struct packed {
    logic [31:0] port_a;
    logic [31:0] port_b;
    logic [31:0] store_data;
    logic [31:0] pc;
    load_t load_type;
    logic byte_en;
    logic dren;
    logic dwen;
    logic wen;
    logic [4:0] reg_rd;
    opcode_t opcode;
  } loadstore_struct_t;

  typedef struct packed {
    aluop_t aluop;
    logic [31:0] port_a;
    logic [31:0] port_b;
    logic [31:0] reg_file_wdata;
    logic [31:0] pc;
    logic wen;
    logic [4:0] reg_rd;
  } arith_struct_t;

  typedef struct packed {
    logic jump_instr;
    word_t j_base;
    word_t j_offset;
    logic j_sel;
  } jump_struct_t;

  typedef struct packed {
    logic branch_instr;
    logic prediction;
    word_t pc4;
  } branch_struct_t;

  typedef struct packed {
    logic csr_instr;
    logic csr_swap;
    logic csr_clr;
    logic csr_set;
    machine_mode_types_1_11_pkg::csr_addr_t csr_addr;
    logic csr_imm;
    logic [31:0] csr_imm_value;
    logic [31:0] instr;
  } csr_struct_t;

  typedef struct packed {
    logic illegal_insn;
    logic breakpoint;
    logic ecall_insn;
    logic ret_insn;
    logic token;
    logic mal_insn;
    logic fault_insn;
    logic wfi;
    w_src_t w_src;
  } exception_control_signals_t;

  typedef struct packed {
    word_t instr;
    word_t pc;
    opcode_t opcode;
    logic [2:0] funct3;
    logic [11:0] funct12;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] reg_rd;
    logic [11:0] imm_S;
    logic [11:0] imm_I;
    word_t imm_U;
    word_t imm_UJ_ext;
    logic [12:0] imm_SB;
    logic instr_30;
  } cpu_tracker_signals_t;

endpackage
`endif //RV32I_TYPES_PKG_SV
