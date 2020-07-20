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
*   Filename:     f_register_file.sv
*   
*   Created by:   Sean Hsu	
*   Email:        hsu151@purdue.edu
*   Date Created: 02/24/2020
*   Description:  floating point register file for the FPU; based on integer reg file
*/
//Modified by Xinlue Liu, Zhengsen Fu
//Last Updated  : 7/19/20

//`include "f_register_file_if.vh"
`include "FPU_if.svh"
`include "register_FPU_if.svh"
module f_register_file (
  input CLK, nRST,
  FPU_if.fp fpa_if,
  register_FPU_if.fp frf_fp
  register_FPU_if.rf frf_rf
);

//  import rv32i_types_pkg::*;

// rs1 and rs2: register locations of two calculation operands
// rd: register location where f_w_data goes

  parameter NUM_REGS = 32;

  logic [31:0] [NUM_REGS-1:0] registers;
  //logic [2:0] frm;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
      frf_fp.frm <= '0;
    end else if (frf_rf.f_wen && frf_rf.f_rd && frf_rf.f_ready && !fpa_if.f_SW) begin 
      registers[frf_rf.f_rd] <= frf_rf.f_w_data;
      frf_fp.frm <= frf_rf.f_frm_in;
     end else begin
      frf_fp.frm <= frf_rf.f_frm_in;
    end
    end
  end 

  assign frf_rf.f_rs1_data = registers[frf_rf.f_rs1];
  assign frf_rf.f_rs2_data = registers[frf_rf.f_rs2];

  assign frf_rf.f_frm_out = frf_fp.frm;
  assign frf_rf.f_flags = {frf_rf.f_NV, frf_rf.f_DZ, frf_rf.f_OF, frf_rf.f_UF, frf_rf.f_NX};


  assign fpa_if.FPU_all_out = fpa_if.f_SW ? registers[frf_rf.f_rs2] : 0; 


endmodule
