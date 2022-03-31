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
*   Created by:   Nicholas Gildenhuys
*   Email:        ngildenh@purdue.edu
*   Date Created: 03/29/2022
*   Description:  Interface for memory arbitor to choose between the 
                  scalar and vector core to service memory requests
*/

`ifndef RV32V_MEMORY_ARBITOR_IF_VH
`define RV32V_MEMORY_ARBITOR_IF_VH

interface rv32v_memory_arbitor_if #(
  parameter NUM_CB_ENTRY=16
)();

  logic [$clog2(NUM_CB_ENTRY)-1:0] cb_tail_index;
  logic [$clog2(NUM_CB_ENTRY)-1:0] vector_cb_index;
  logic [$clog2(NUM_CB_ENTRY)-1:0] scalar_cb_index;
  logic v_ena, s_ena;

  modport arbitor (
    input v_ena, cb_tail_index, vector_cb_index, scalar_cb_index
  );
  modport datapath (
    output v_ena, cb_tail_index, vector_cb_index, scalar_cb_index
  );
endinterface

`endif //RV32V_MEMORY_ARBITOR_IF
