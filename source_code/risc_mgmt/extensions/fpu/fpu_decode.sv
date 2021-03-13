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

module fpu_decode (
  input logic CLK, nRST,
  //risc mgmt connection
  risc_mgmt_decode_if.ext dif,
  //stage to stage connection
  output fpu_pkg::decode_execute_t idex
);
  import fpu_pkg::*; //import packages that has parameter decodings

  fpu_insn_t insn;

  parameter OPCODE = FPU_OPCODE_ARI | FPU_OPCODE_LD | FPU_OPCODE_SW;//load, store, or arithmetic operation

  assign insn = fpu_insn_t'(dif.insn);

  assign dif.insn_claim = fpu_insn_t'(insn.opcode == OPCODE); //load/store not sure
  assign dif.mem_to_reg = 1'b0; //Not writing to memory
  
  //register locations
  assign dif.rsel_s_0 = insn.rs1;
  assign dif.rsel_s_1 = insn.offset_rs2;
  assign dif.rsel_d = insn.rd_offset;

  //execute signals.
  assign idex.start = dif.insn_claim;
  always_comb begin
    idex.funct7 = '1;
    idex.load = 0;
    idex.store = 0;
    idex.rs1 = '0;
    idex.rs2 = '0;
    idex.rd = '0;
    idex.imm = '0;
    idex.frm = '1;
    if (OPCODE == FPU_OPCODE_LD) begin
      idex.imm = {insn.offset_funct5, insn.offset_fmt, insn.offset_rs2};
      idex.load = 1'b1;
      idex.rs1 = insn.rs1;
      idex.rd = insn.rd;
    end else if (OPCODE == FPU_OPCODE_SW) begin
      idex.imm = {insn.offset_funct5, insn.offset_fmt, insn.rd_offset};
      idex.store = 1'b1;
      idex.rs2 = insn.rs2;
      idex.rs1 = insn.rs1;
    end else if (OPCODE == FPU_OPCODE_ARI) begin
      idex.funct7 = {offset_funct5, offset_fmt};
      idex.rs2 = insn.offset_rs2;
      idex.rs1 = insn.rs1;
      idex.rd = insn.rd_offset;
      idex.frm = insn.width_rm;
    end
  end

endmodule
