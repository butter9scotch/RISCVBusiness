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
interface element_counter_if # (
  parameter NUM_COUNTERS = 1
) ();

  import rv32i_types_pkg::*;
  
  offset_t [NUM_COUNTERS-1:0]        offset;
  logic    [NUM_COUNTERS-1:0]        done, next_done;
  logic    [NUM_COUNTERS-1:0][31:0]  vstart, vl;
  logic    [NUM_COUNTERS-1:0]        stall, ex_return, de_en, clear, busy_ex;

  modport decode (
    input   vstart, vl,
            stall, ex_return, de_en,
            clear, busy_ex, 
    output  offset,  done, next_done
  );

endinterface
`endif
