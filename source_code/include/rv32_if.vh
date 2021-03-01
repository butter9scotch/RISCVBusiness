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
*   Filename:     include/rv32f_reg_file_if.vh
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 03/1/2021
*   Description:  Interface for the FPU 
*/

`ifndef RV32F_REG_FILE_IF_VH
`define RV32I_REG_FILE_IF_VH

interface rv32f_if();

  import rv32f_types_pkg::*;

  word_t        FPU_all_out, dload_ext;
  logic 		sw, wen, lw;
  logic [4:0] 	rs1, rs2, rd;
  funct7_t		f_funct7;
  logic [2:0]   frm;

  //privilege signals
  logic [4:0] f_flags;
  logic [2:0] f_frm_out;

  modport fpu (
    input sw, lw, wen, ren, rs1, rs2, rd, frm, dload_ext, f_funct7,
    output FPU_all_out, f_flags, f_frm_out
  );


endinterface

`endif //RV32I_REG_FILE_IF_VH
