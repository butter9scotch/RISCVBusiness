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


//`include "f_register_file_if.vh"

module f_register_file (
  input CLK, nRST,
  f_register_file_if.rf frf_if
);

//  import rv32i_types_pkg::*;

// rs1 and rs2: register locations of two calculation operands
// rd: register location where f_w_data goes

  parameter NUM_REGS = 32;

  logic [31:0] [NUM_REGS-1:0] registers;
  logic [2:0] frm;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
      frm <= '0;
    end else if (frf_if.f_wen && frf_if.f_rd && f_ready && !f_SW) begin //interface need to add input f_ready signal from fpu
      registers[frf_if.f_rd] <= frf_if.f_w_data;
      frm <= frf.f_frm_in;
    end else if (frf_if.wen && f_SW) begin
      registers[frf_if.f_rs2] <= registers[frf_if.f_rs1 + imm]; //imm is a 12 bit offset from ALU
    end else begin <= frf.f_frm_in;
    end
  end 

  assign frf_if.f_rs1_data = registers[frf_if.f_rs1];
  assign frf_if.f_rs2_data = registers[frf_if.f_rs2];

  assign frf_if.FPU_all_out = registers[frf_if.f_rs2]; //interface need to add input FPU_all_out as the output data to be stored in memory, selected by f_sw

  assign frf.f_frm_out = frm;
  assign frf.f_flags = {frf.f_NV, frf.f_DZ, frf.f_OF, frf.f_UF, frf.f_NX};


endmodule
