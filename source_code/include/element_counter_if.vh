/*
*   Copyright 2021 Purdue University
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
*   Filename:     element_counter_if.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 10/13/2021
*   Description:  Interface for element counter
*                  
*/

`ifndef ELEMENT_COUNTER_IF_VH
`define ELEMENT_COUNTER_IF_VH
interface element_counter_if();
  import rv32i_types_pkg::*;
  // import rv32i_types_pkg::*;
  
  offset_t offset;
  logic  done, next_done;

  word_t vstart, vl;
  logic stall, ex_return, de_en, clear, busy_ex, slide1up;

  modport decode (
    input   vstart, vl,
            stall, ex_return, de_en,
            clear, busy_ex, slide1up,
    output  offset,  done, next_done
  );


  // modport decode (
  // );
endinterface
`endif
