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

  word_t  [NUM_LANES - 1:0]  w_data, vs1_data, vs2_data;
  logic   [4:0] vs1, vs2, vd;
  sew_t de_sew, wb_sew;                  //8, 16, 32 bit elements
  logic [VL_WIDTH - 1:0] de_vl, wb_vl;  //number of elements in the vector
  offset_t vs1_offset, vs2_offset, vd_offset;
  logic wen;
  logic write_single_bit;
  logic [1:0] vs1_mask, vs2_mask;

  modport rf (
    input w_data, vs1, vs2, vd, wen, 
          de_sew, de_vl, //for decode stage
          wb_sew, wb_vl, //for wb stage
          vs1_offset, vs2_offset, vd_offset,
          write_single_bit,
    output vs1_data, vs2_data, vs1_mask, vs2_mask
  );
  
  modport decode (
    output  vs1, vs2, vs1_offset, vs2_offset, de_sew, de_vl,
    input   vs1_data, vs2_data, vs1_mask, vs2_mask
  );

  modport writeback (
    input w_data, vd, wen, write_single_bit, vd_offset, wb_sew, wb_vl
  );

endinterface

`endif //RV32V_REG_FILE_IF_VH
