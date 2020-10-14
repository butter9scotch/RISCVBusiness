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
*   Filename:     template_execute.sv
*
*   Created by:   <author>
*   Email:        <author email>
*   Date Created: <date> 
*   Description:  This extension is the Template for creating rytpe custom
*                 instructions. 
*/

`include "risc_mgmt_execute_if.vh"

module fpu_execute (
  input logic CLK, nRST,
  //risc mgmt connection
  risc_mgmt_execute_if.ext eif,
  //stage to stage connection
  input   rv32f_pkg::decode_execute_t idex,
  output  rv32f_pkg::execute_memory_t exmem
);
  import rv32f_pkg::*;

   logic [31:0] fpu_result_temp;
   logic [4:0] flags_result_temp;
   logic [2:0] frm_result_temp;
  FPU_all fpu_all ( //not imported yet maybe
    .n_rst(nRST),
    .clk(CLK),
    .f_rd(idex.rd),
    .f_rs1(idex.rs1),
    .f_rs2(idex.rs2),
    .f_frm_in(idex.frm),
    .f_LW(idex.load),
    .f_SW(idex.store),
    .f_funct_7(idex.funct7),
    .fload_ext(eif.rdata_s_0),
    .FPU_all_out(fpu_result_temp),
    .f_flags(flags_result_temp),
    .f_frm_out(frm_result_temp)
  );

  always_ff @ (posedge CLK, negedge nRST) begin //not sure
    if (~nRST) begin
      exmem.fpu_result <= '0;
      exmem.flags_result <= '0;
      exmem.frm_result <= '0;
    end if (eif.start == 1'b1) begin
      exmem.fpu_result <= fpu_result_temp;
      exmem.flags_result <= flags_result_temp;
      exmem.frm_result <= frm_result_temp;
    end
  end

  assign eif.exception = 1'b0;
  assign eif.branch_jump = 1'b0;

  assign eif.busy = 1'b0; //should I output f_ready(to stop)

  //should I write data now or later
  assign eif.reg_w = 1'b1;
  assign eif.reg_wdata = fpu_result_temp; //but we have three outputs(fpu_out, flags, and frm)

endmodule
