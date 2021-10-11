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
*   Filename:     include/rv32v_reg_file_if.vh
*
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/10/2021
*   Description:  Interface for Vector extension register file
*/

`ifndef RV32V_REG_FILE_IF_VH
`define RV32V_REG_FILE_IF_VH

interface rv32v_reg_file_if();

  import rv32v_types_pkg::*;
  import rv32i_types_pkg::*;

  parameter WEN_WIDTH = 4;
  parameter NUM_LANES = 2;

  word_t  [NUM_LANES - 1:0]  w_data;
  // word_t   w_data;
  word_t  [NUM_LANES - 1:0]  rs1_data, rs2_data;
  logic   [4:0] rs1, rs2, rd;
  logic   [WEN_WIDTH - 1:0] wen;

  modport rf (
    input w_data, rs1, rs2, rd, wen,
    output rs1_data, rs2_data
  );
  
  modport decode (
    output  rs1, rs2,
    input   rs1_data, rs2_data
  );

  modport writeback (
    input w_data, rd, wen
  );

endinterface

`endif //RV32V_REG_FILE_IF_VH
