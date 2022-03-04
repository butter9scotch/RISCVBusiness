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
*   Filename:     src/rv32i_reg_file.sv
*
*   Created by:   John Skubic
*   Email:        jskubic@purdue.edu
*   Date Created: 06/14/2016
*   Description:   Integer Register File.  Register 0 will always output 0.
*/

`include "rv32i_reg_file_if.vh"

module rv32i_reg_file (
  input CLK, nRST,
  rv32i_reg_file_if.rf rf_if
);

  import rv32i_types_pkg::*;

  parameter NUM_REGS = 32;

  word_t [NUM_REGS-1:0] registers;
  logic [31:0] in_use;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
      in_use <= '0;
    end else begin
      if (rf_if.wen && rf_if.rd) begin
        registers[rf_if.rd] <= rf_if.w_data;
        in_use[rf_if.rd] <= 1'b0;
      end
      if (rf_if.rden && rf_if.rd_decode) begin
        in_use[rf_if.rd_decode] <= 1'b1;
      end
    end
  end 

  assign rf_if.rs1_data = registers[rf_if.rs1];
  assign rf_if.rs2_data = registers[rf_if.rs2];
  assign rf_if.rs1_busy = in_use[rf_if.rs1];
  assign rf_if.rs2_busy = in_use[rf_if.rs2];
  assign rf_if.rd_busy  = in_use[rf_if.rd_decode];

endmodule
