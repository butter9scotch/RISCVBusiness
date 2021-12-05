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
`define TESTBENCH

interface rv32v_reg_file_if();

  import rv32v_types_pkg::*;
  import rv32i_types_pkg::*;

  word_t  [NUM_LANES - 1:0]  w_data, vs1_data, vs2_data, vs3_data;
  word_t  mask_32bit_lane0, mask_32bit_lane1;
  logic   [4:0] vs1, vs2, vs3, vd;
  sew_t   sew, vs2_sew;                  //8, 16, 32 bit elements
  sew_t   eew;                  //8, 16, 32 bit elements
  logic   [VL_WIDTH:0]  vl;  //number of elements in the vector
  offset_t vs1_offset, vs2_offset, vs3_offset, vd_offset;
  logic   [1:0] wen;
  logic   [1:0] vs1_mask, vs2_mask, vs3_mask;
  // logic vs2_;
  logic single_bit_write;

  modport rf (
    input w_data, vs1, vs2, vs3, vd, wen, 
          sew, eew, vs2_sew, vl, //for wb stage
          vs1_offset, vs2_offset, vs3_offset, vd_offset, single_bit_write,
          
    output vs1_data, vs2_data, vs3_data, vs1_mask, vs2_mask, vs3_mask, mask_32bit_lane0, mask_32bit_lane1
  );
  
  modport decode (
    input  vs1, vs2, vs3, vs1_offset, vs2_offset, vs3_offset, sew, vs2_sew, vl,
    output   vs1_data, vs2_data, vs3_data, vs1_mask, vs2_mask, vs3_mask, mask_32bit_lane0, mask_32bit_lane1
  );

  modport writeback (
    input w_data, vd, wen, vd_offset, eew, vl, single_bit_write
  );

endinterface

`endif //RV32V_REG_FILE_IF_VH
