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

  localparam FPU_ADDSUBMUL = 7'b1010011; //op_code for add, sub, mul
  localparam FPU_ADD = 7'b0000000;
  localparam FPU_SUB = 7'b0000100;
  localparam FPU_MUL = 7'b0001000;
  localparam FPU_LD = 7'b0000111;
  localparam FPU_SW = 7'b0100111;

  typedef struct packed {
    logic [4:0] rs2;
    logic [4:0] rs1;
    logic [4:0] rd;
    logic [2:0] frm_in;
    logic [6:0] funct_7;
    logic [31:0] dload_ext;
    logic lw;
    logic sw;
  } fpu_insn_t;

  // Interface between the decode and execute stage
  // This must be named "decode_execute_t"
  typedef struct packed {
    logic start;
    logic add;
    logic sub;
    logic mul;
    logic frm;
    logic load;
    logic store;
  } decode_execute_t;

  // Interface between the execute and memory stage
  // This must be named "execute_memory_t"
  typedef struct packed {
    logic signal;
  } execute_memory_t;

  

endpackage

`endif //FPU_PKG_SV
