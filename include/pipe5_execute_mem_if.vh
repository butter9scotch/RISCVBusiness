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
*   Filename:     tspp_fetch_execute_if.vh
*   
*   Created by:   Jacob R. Stevens	
*   Email:        steven69@purdue.edu
*   Date Created: 06/01/2016
*   Description:  Interface between the fetch and execute pipeline stages
*/

`ifndef PIPE5_EXECUTE_MEM_IF_VH
`define PIPE5_EXECUTE_MEM_IF_VH

interface pipe5_execute_mem_if;
  import rv32i_types_pkg::*;
 
  word_t       reg_file_wdata;
  word_t       store_wdata;
  word_t       alu_port_out;
  word_t       memory_addr;
  word_t       reg_rd;
  word_t       pc;
  word_t       pc4;
  load_t       load_type;
  branch_t     branch_type;
  logic [3:0]  byte_en_temp;
  logic [2:0]  w_sel;
  logic        wen;
  logic        dwen;
  logic        dren;
  logic        jump_instr;
  logic        branch_instr;
  logic        prediction;
  logic        halt_instr;
  logic        ifence;


  modport execute(
     output  reg_file_wdata, w_sel, wen, alu_port_out, pc, pc4, reg_rd,
             dwen, dren, store_wdata, load_type, memory_addr,byte_en_temp,
             jump_instr, 
             branch_instr, prediction,
             ifence,
             halt_instr
  );

  modport memory(
     input   reg_file_wdata, w_sel, wen, alu_port_out, pc, pc4, reg_rd,
             dwen, dren, store_wdata, load_type, memory_addr, byte_en_temp,
             jump_instr, 
             branch_instr, prediction,
             ifence,
             halt_instr
  );

endinterface
`endif

