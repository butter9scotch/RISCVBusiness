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
*   Filename:     multiply_unit_if.vh
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 02/19/2022
*   Description:  Interface for multiply unit
*/

`ifndef MULTIPLY_UNIT_IF_VH
`define MULTIPLY_UNIT_IF_VH

interface multiply_unit_if();

  import rv32i_types_pkg::*;

  logic [31:0] rs1_data;
  logic [31:0] rs2_data;
  logic start_mu;
  logic high_low_sel;
  logic decode_done;
  logic wen;
  logic wen_mu;
  sign_type_t is_signed;
  logic [4:0] reg_rd;
  logic [4:0] reg_rd_mu;
  logic [31:0] wdata_mu;
  logic busy_mu;
  logic done_mu;

  modport execute (
    input rs1_data, rs2_data, start_mu, high_low_sel, decode_done, wen, 
          is_signed, reg_rd, 
    output wdata_mu, busy_mu, done_mu, wen_mu, reg_rd_mu
  );

endinterface

`endif //MULTIPLY_UNIT_IF_VH
