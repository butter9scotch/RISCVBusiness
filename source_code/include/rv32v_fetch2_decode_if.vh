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
*   Date Created: 10/30/2021
*   Description:  Decode-execute interface for vector extension 
*/

`ifndef RV32V_FETCH2_DECODE_IF_VH
`define RV32V_FETCH2_DECODE_IF_VH

interface rv32v_fetch2_decode_if();

  import rv32i_types_pkg::*;

  word_t        instr;
  logic         mal_insn;
  logic         fault_insn;

  int tb_line_num;

  modport fetch(
    output  instr, mal_insn, fault_insn
  );

  modport decode(
    input   instr, mal_insn, fault_insn 
  );

endinterface

`endif //RV32V_FETCH2_DECODE_IF_VH
