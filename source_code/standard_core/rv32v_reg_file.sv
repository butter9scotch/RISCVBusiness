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
*   Filename:     src/rv32v_reg_file.sv
*
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/10/2021
*   Description:   Vector Register File
*/

`include "rv32v_reg_file_if.vh"

module rv32v_reg_file (
  input CLK, nRST,
  rv32v_reg_file_if.rf rfv_if
);

  import rv32v_types_pkg::*;
  import rv32i_types_pkg::*;
  // parameter VLENB = 8;

  typedef logic [7:0] byte_t;
  typedef byte_t [VLENB-1:0]  vreg_t;
  // typedef [7:0] byte_t vreg_t;


  parameter NUM_REGS = 32;

  vreg_t [NUM_REGS-1:0] registers, next_registers;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
    end else begin
      registers <= next_registers;
    end
  end 

  always_comb begin
    next_registers = registers;
    if (rfv_if.wen == 4'b1111) begin
      next_registers[rfv_if.rd][7:4] = rfv_if.w_data[1][31:0];
      next_registers[rfv_if.rd][3:0] = rfv_if.w_data[0][31:0];
    end else if (rfv_if.wen == 4'b0011) begin
      next_registers[rfv_if.rd][3:2] = rfv_if.w_data[1][15:0];
      next_registers[rfv_if.rd][1:0] = rfv_if.w_data[0][15:0];
    end else if (rfv_if.wen == 4'b0001) begin
      next_registers[rfv_if.rd][1]   = rfv_if.w_data[1][7:0]; //1 byte 
      next_registers[rfv_if.rd][0]   = rfv_if.w_data[0][7:0]; //1 byte 
    end
  end




  assign rfv_if.rs1_data = registers[rfv_if.rs1][7:0];
  assign rfv_if.rs2_data = registers[rfv_if.rs2][7:0];

endmodule
