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
*   Filename:     template_decode.sv
*
*   Created by:   <author> 
*   Email:        <author email>
*   Date Created: <date>
*   Description:  This extension is the Template for creating rytpe custom
*                 instructions. 
*/

`include "risc_mgmt_decode_if.vh"

module template_decode (
  input logic CLK, nRST,
  //risc mgmt connection
  risc_mgmt_decode_if.ext dif,
  //stage to stage connection
  output fpu_pkg::decode_execute_t idex
);
  import fpu_pkg::*; //import packages that has parameter decodings
  fpu_insn_t insn;
  parameter OPCODE = FPU_ADDSUBMUL | FPU_LD | FPU_SW;//load store?

  assign insn = fpu_insn_t'(dif.insn);

  //prevent from accessing core ?
  assign dif.insn_claim = fpu_insn_t'((insn.funct_7 == FPU_ADD)|(insn.funct_7 == FPU_SUB)|(insn.funct_7 == FPU_MUL)|(insn.funct_7 == FPU_LD)|(insn.funct_7 == FPU_SW)); //load/store not sure
  assign dif.mem_to_reg = 1'b0; //register read, so this is 0. Not writing to memory
  //register locations
  assign dif.rsel_s_0 = insn.rs1;
  assign dif.rsel_s_1 = insn.rs2;
  assign dif.rsel_d = insn.rd;

  //decode funct. Communicate with execute which performs arithmetic operations
  assign idex.start = dif.insn_claim; //no start in crc
  assign idex.add = (insn.funct == 7'b0000000);
  assign idex.sub = (insn.funct == 7'b0001000);
  assign idex.mul = (insn.funct == 7'b0000100);
  assign idex.frm = (insn.frm == 3'b000) | (insn.frm == 3'b001) | (insn.frm == 3'b010) | (insn.frm == 3'b011) | (insn.frm == 3'b100);
  assign idex.load = (insn.lw == 1'b1);
  assign idex.store = (insn.sw == 1'b1);

endmodule
