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
*   Filename:     rv32f_types_pkg.sv
*   
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 02/24/2021
*   Description:  Package containing types used for a RV32F implementation
*/

`ifndef RV32F_TYPES_PKG_SV
`define RV32F_TYPES_PKG_SV
package rv32f_types_pkg;
  parameter WORD_SIZE = 32;
  parameter RAM_ADDR_SIZE = 32;
  parameter IMM_SIZE = 12;
  parameter OP_W = 7;
  parameter WIDTH_W = 3;
  parameter FUNCT7_W = 7;
  parameter FMT_W = 2;
  parameter RM_W = 3;

  typedef logic [WORD_SIZE-1:0] word_t;

  //typedef enum logic [FUNCT7_W-1:0] {
  //FLW = 7'b0000111,
  //} opcode_t;
  
  typedef enum logic [FUNCT7_W - 1:0] {
  	FADD = 7'b0000001,
	FSUB = 7'b0000101,
	FMUL = 7'b0001001
	} funct7_t;

	typedef struct packed {
		logic [11:0] imm;
		logic [4:0]  rs1;
		logic [2:0]  rm;
		logic [4:0]  rd;
		opcode_t opcode;
	} flwtype_t;

	typedef struct packed {
		logic [6:0] imm_upper;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] rm;
		logic [4:0] imm_lower;
		opcode_t opcode;
	} fswtype_t;


	typedef struct packed {
		funct7_t    funct7;
		logic [4:0] rs2;
		logic [4:0] rs1;
		logic [2:0] rm;
		logic [4:0] rd;
		opcode_t opcode;
	} fregreg_t;


endpackage
`endif
