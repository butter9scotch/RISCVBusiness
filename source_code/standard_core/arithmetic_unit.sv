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
*   Filename:     arithmetic_unit.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 2/23/2022
*   Description:  Load store functional unit
*/

`include "arithmetic_unit_if.vh"
`include "alu_if.vh"

module arithmetic_unit (
  arithmetic_unit_if.au auif
);
  
  import rv32i_types_pkg::*;

  alu_if aluif();
  alu ALU (.alu_if(aluif));

  assign aluif.port_a = auif.port_a;
  assign aluif.port_b = auif.port_b;
  assign aluif.aluop  = auif.aluop;
  // assign auif.wen_au

  // assign wdata_au = csr_instr_sel ? auif.csr_rdata : aluif.port_out;
  always_comb begin
    case(auif.w_src)
    CSR:     auif.wdata_au = auif.csr_rdata;
    ALU_SRC: auif.wdata_au = aluif.port_out;
    default: auif.wdata_au = auif.reg_file_wdata;
    endcase
  end
  // auif.wen = auif.wen_au; 



endmodule
