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

`ifndef PIPE5_FETCH2_DECODE_IF_VH
`define PIPE5_FETCH2_DECODE_IF_VH

interface pipe5_fetch2_decode_if;
  import rv32i_types_pkg::*;
 
  logic         token;
  word_t        pc;
  word_t        pc4;
  word_t        instr;
  word_t        prediction;
  word_t brj_addr;

  modport fetch(
    output  pc, token, pc4, instr, prediction,
    input   brj_addr //This is the resolved branch/jump address; will come from memstage (actually hazard unit) 
  );

  modport decode(
    input    pc, token, pc4, instr, prediction,
    output   brj_addr //This is the resolved branch/jump address; will come from memstage (actually hazard unit) 
  );

endinterface
`endif
