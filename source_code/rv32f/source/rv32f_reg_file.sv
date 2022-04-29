/*   Copyright 2016 Purdue University
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
*   Filename:     f_register_file.sv
*   
*   Created by:   Sean Hsu	
*   Email:        hsu151@purdue.edu
*   Date Created: 02/24/2020
*   Description:  floating point register file for the FPU; based on integer reg file
*/
//Modified by Xinlue Liu, Zhengsen Fu
//Last Updated  : 7/21/20

//`include "f_register_file_if.vh"
//`include "FPU_if.svh"
`include "rv32f_reg_file_if.vh"
module rv32f_reg_file (
  // FPU_if.fp fpa_if,
  // register_FPU_if.fp frf_fp
  rv32f_reg_file_if.rf frf_rf
);

//  import rv32i_types_pkg::*;

// rs1 and rs2: register locations of two calculation operands
// rd: register location where f_wdata goes

  parameter NUM_REGS = 32;

  logic [31:0] [NUM_REGS-1:0] registers;

  always_ff @ (posedge frf_rf.clk, negedge frf_rf.n_rst) begin
    if (~frf_rf.n_rst) begin
      for (int i = 0; i < 32; i++) begin
          registers[i] <= 'h7fc00000;
      end
    end else if (frf_rf.f_wen) begin 
      registers[frf_rf.f_rd] <= frf_rf.f_wdata; 
    end else begin
    end
  end 


  assign frf_rf.f_rs1_data = registers[frf_rf.f_rs1];
  assign frf_rf.f_rs2_data = registers[frf_rf.f_rs2];

endmodule
