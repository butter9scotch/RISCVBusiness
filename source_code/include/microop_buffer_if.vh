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

`ifndef MICROOP_BUFFER_IF_VH
`define MICROOP_BUFFER_IF_VH

interface microop_buffer_if;
  logic [3:0] LMUL;
  logic shift_ena;
  logic start;
  logic clear;
  logic [31:0] instr;
  logic [31:0] microop;

  modport decode (
    input instr,
    output LMUL, shift_ena, start, clear, microop
  );

endinterface

`endif //MICROOP_BUFFER_IF_VH

  