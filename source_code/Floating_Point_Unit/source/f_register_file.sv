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
/*    input f_w_data, f_rs1, f_rs2, f_rd, f_wen, f_NV, f_DZ, f_OF, f_UF, f_NX, f_frm_in, 
    output f_rs1_data, f_rs2_data, f_frm_out, f_flags*/
);

//  import rv32i_types_pkg::*;
//  Count cycles for fready

  parameter NUM_REGS = 32;

  logic [31:0] [NUM_REGS-1:0] registers;
  logic [2:0] frm;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
      frm <= '0;
    end else if (frf_if.f_wen && frf_if.f_rd) begin //fwen write enable, rd destination register. 
      registers[frf_if.f_rd] <= frf_if.f_w_data; //put f_w_data into registers
      frm <= frf.f_frm_in;
    end else begin
      frm <= frf.f_frm_in;
    end
  end 

  assign frf_if.f_rs1_data = registers[frf_if.f_rs1];
  assign frf_if.f_rs2_data = registers[frf_if.f_rs2];

  assign frf.f_frm_out = frm;
  assign frf.f_flags = {frf.f_NV, frf.f_DZ, frf.f_OF, frf.f_UF, frf.f_NX};


endmodule
