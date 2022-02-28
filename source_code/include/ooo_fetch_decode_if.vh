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
*   Filename:     ooo_fetch_decode_if.vh
*   
*   Created by:   Nicholas Gildenhuys	
*   Email:        ngildenh@purdue.edu
*   Date Created: 02/27/2022
*   Description:  Interface between the fetch and decode pipeline stages 
*                 in the out of order core
*/


`ifndef OOO_FETCH_DECODE_IF_VH
`define OOO_FETCH_DECODE_IF_VH

interface ooo_fetch_decode_if;

  import rv32i_types_pkg::*;

  logic   token;
  word_t  pc;
  word_t  pc4;
  word_t  instr;
  logic   mal_insn;
  logic   fault_insn;
  logic   prediction;

  modport fetch(
    output token, pc, pc4, instr, mal_insn, fault_insn, prediction
  );

  modport decode(
    input token, pc, pc4, instr, mal_insn, fault_insn, prediction
  );

endinterface
`endif //OOO_FETCH_DECODE_IF_VH
