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
*   Filename:     include/rv32f_if.vh
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 03/1/2021
*   Description:  Interface for the FPU 
*/

`ifndef RV32F_REG_FILE_IF_VH
`define RV32F_REG_FILE_IF_VH

interface rv32f_if();

  import rv32i_types_pkg::*;

  word_t  floating_point1, floating_point2, floating_point_out;
	logic [2:0] frm;
	logic [6:0] funct7;
  logic [4:0] flags;

  modport fpu (
    input floating_point1, floating_point2, frm, funct7,
    output floating_point_out, flags, f_stall
  );
	

endinterface

`endif //RV32F_REG_FILE_IF_VH
