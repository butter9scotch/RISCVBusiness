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
*   Filename:     include/rv32i_reg_file_if.vh
*
*   Created by:   John Skubic
*   Email:        jskubic@purdue.edu
*   Date Created: 06/14/2016
*   Description:  Interface for the Register File 
*/

`ifndef RV32I_REG_FILE_IF_VH
`define RV32I_REG_FILE_IF_VH

interface rv32i_reg_file_if();

  import rv32i_types_pkg::*;

  word_t        w_data, rs1_data, rs2_data;
  logic   [4:0] rs1, rs2, rd, rd_decode;
  logic         wen;
  logic         rden;
  logic         rs1_busy;
  logic         rs2_busy;
  logic         rd_busy;
  logic         clear_status;

  modport rf (
    input w_data, rs1, rs2, rd, wen, rden, rd_decode,
    output rs1_data, rs2_data, rs1_busy, rs2_busy, rd_busy, clear_status
  );
  
  modport decode (
    output  rs1, rs2, rden, rd_decode, 
    input   rs1_data, rs2_data, rs1_busy, rs2_busy, rd_busy, clear_status
  );

  modport writeback (
    input w_data, rd, wen
  ); 

endinterface

`endif //RV32I_REG_FILE_IF_VH
