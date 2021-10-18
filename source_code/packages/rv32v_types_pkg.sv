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
*   Filename:     rv32v_types_pkg.sv
*   
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/10/2021
*   Description:  Package containing types used for a RV32V implementation
*/

`ifndef RV32V_TYPES_PKG_SV
`define RV32V_TYPES_PKG_SV
// `include "rv32i_types_pkg.sv";

package rv32v_types_pkg;
  parameter VLEN_WIDTH = 7; // 128 bit registers
  parameter VL_WIDTH = VLEN_WIDTH; //width of largest vector = VLENB * 8 
  parameter VLEN = 1 << 7; 
  parameter VLENB = VLEN / 8; //VLEN in bytes
  parameter NUM_LANES = 2;


  typedef enum logic [2:0]  {
    SEW8    = 3'd0, 
    SEW16   = 3'd1,  
    SEW32   = 3'd2,
    SEW64   = 3'd3,
    SEW128  = 3'd4,
    SEW256  = 3'd5,
    SEW512  = 3'd6,
    SEW1024 = 3'd7
  } sew_t;

  typedef enum logic [2:0] {
    LMUL1       = 3'd0,
    LMUL2       = 3'd1,
    LMUL4       = 3'd2,
    LMUL8       = 3'd3,
    LMULHALF    = 3'd5,
    LMULFOURTH  = 3'd6,
    LMULEIGHTH  = 3'd7
  } vlmul_t;


  typedef logic [VLEN_WIDTH: 0] offset_t; //bits needed to hold offset
  typedef logic [7:0] byte_t;
  typedef byte_t [VLENB-1:0]  vreg_t;

  typedef enum logic [2:0] {
    ARITH   = 3'b000,
    RED     = 3'b001,
    MUL     = 3'b010,
    DIV     = 3'b011,
    MASK    = 3'b100,
    PEM     = 3'b101,
    LOAD    = 3'b110,
    STORE   = 3'b111
  } fu_t;

  typedef enum logic [3:0] {
    ALU_SLL   = 4'b0000,
    ALU_SRL   = 4'b0001,
    ALU_SRA   = 4'b0010,
    ALU_ADD   = 4'b0011,
    ALU_SUB   = 4'b0100,
    ALU_AND   = 4'b0101,
    ALU_OR    = 4'b0110,
    ALU_XOR   = 4'b0111,
    ALU_COMP  = 4'b1000,
    ALU_MERGE = 4'b1001,
    ALU_MOVE  = 4'b1010,
    ALU_MM    = 4'b1011,
    ALU_EXT   = 4'b1100
  } valuop_t;

  typedef enum logic [2:0] {
    SEQ   = 3'b000,
    SNE   = 3'b001,
    SLTU  = 3'b010,
    SLT   = 3'b011,
    SLEU  = 3'b100,
    SLE   = 3'b101,
    SGTU  = 3'b110,
    SGT   = 3'b111
  } comp_t;

  typedef enum logic [2:0] {
    MIN   = 3'b00,
    MINU  = 3'b01,
    MAX   = 3'b10,
    MAXU  = 3'b11
  } mm_t;

  typedef enum logic [3:0] {
    NORMAL  = 4'b0000,
    A_S     = 4'b0001,
    MULTI   = 4'b0010,
    DIVI    = 4'b0011,
    REM     = 4'b0100
  } athresult_t;

  typedef enum logic [2:0] {
    F2Z = 3'b000,
    F2S = 3'b001,
    F4Z = 3'b010,
    F4S = 3'b011,
    F8Z = 3'b100,
    F8S = 3'b101
  } ext_t;
  
endpackage
`endif
