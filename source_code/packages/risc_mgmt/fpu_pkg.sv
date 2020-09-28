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
*   Filename:     rv32m_pkg.sv
*
*   Created by:   John Skubic
*   Email:        jskubic@purdue.edu
*   Date Created: 02/07/2017
*   Description:  Types for the RV32M standard extension 
*/

`ifndef FPU_PKG_SV
`define FPU_PKG_SV

package fpu_pkg;

  localparam FPU_OPCODE_ARI = 7'b1010011; //opcode for arithmetic operation
  localparam FPU_OPCODE_LD = 7'b0000111;  //opcode for load
  localparam FPU_OPCODE_SW = 7'b0100111;  //opcode for store

  //funct7(funct5 + fmt) for arithemtic operation
  localparam FPU_FUNCT_ADD = 7'b0000000;  
  localparam FPU_FUNCT_SUB = 7'b0000100;
  localparam FPU_FUNCT_MUL = 7'b0001000;

  typedef struct packed {
    logic [4:0] offset_funct5; //this may be imm[11:7] or funct5[4:0]
    logic [1:0] offset_fmt;    //this may be imm[6:5] or fmt(.S will be 00)
    logic [4:0] offset_rs2;    //this may be imm[4:0] or rs2
    logic [4:0] rs1;           //register select 1
    logic [2:0] width_rm;      //this may be width[2:0] or rm
    logic [4:0] rd_offset;     //this may be imm[4:0] or rd
    logic [6:0] opcode;        //opcode
    logic [23:0] Reserved;     //reserved for other extension
    logic [2:0] frm;           //rounding mode
    logic [4:0] flags;         //flags(NV, DZ, OF, UF, NX)
    } fpu_insn_t; //32 bit instruction and 32 bit fcsr

  // Interface between the decode and execute stage
  // This must be named "decode_execute_t"
  typedef struct packed {
    logic add;
    logic sub;
    logic mul;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic [11:0] imm;
  } decode_execute_t; //fcsr

  // Interface between the execute and memory stage
  // This must be named "execute_memory_t"
  typedef struct packed {
    logic signal;
  } execute_memory_t; //doesn't output. Take leftover signals from execute. Load or store/bypass and go to memory . reg_w should be 0

  

endpackage

`endif //FPU_PKG_SV
