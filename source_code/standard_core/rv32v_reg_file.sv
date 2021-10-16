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




  parameter NUM_REGS = 32;
  logic [6:0] vd1_start, vd2_start;
  logic [6:0] vd1_end, vd2_end;
  

  vreg_t [NUM_REGS-1:0] registers, next_registers;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
    end else begin
      registers <= next_registers;
    end
  end 

  always_comb begin : WRITE_DATA
    next_registers = registers;
    if (rfv_if.wen & rfv_if.sew == SEW32) begin //4 byte
      if ((rfv_if.vd_offset + 2) << 2 > VLENB) $info("Illegal 32bit write address: vd_offset = %d", rfv_if.vd_offset);
      if (rfv_if.vd_offset < rfv_if.vl) begin
        next_registers[rfv_if.vd][(rfv_if.vd_offset << 2) +:4]       = rfv_if.w_data[0][31:0];
      end
      if (rfv_if.vd_offset + 1 < rfv_if.vl) begin
        next_registers[rfv_if.vd][((rfv_if.vd_offset + 1) << 2) +:4] = rfv_if.w_data[1][31:0];
      end
    end else if (rfv_if.wen & rfv_if.sew == SEW16) begin //2 byte
      if ((rfv_if.vd_offset + 2) << 1 > VLENB)  $info("Illegal 16bit write address: vd_offset = %d", rfv_if.vd_offset);
      if (rfv_if.vd_offset < rfv_if.vl) begin
        next_registers[rfv_if.vd][(rfv_if.vd_offset << 1) +:2]       = rfv_if.w_data[0][15:0]; 
      end
      if ((rfv_if.vd_offset + 1) < rfv_if.vl) begin
        next_registers[rfv_if.vd][((rfv_if.vd_offset + 1) << 1) +:2] = rfv_if.w_data[1][15:0];
      end
    end else if (rfv_if.wen & rfv_if.sew == SEW8) begin //1 byte
      if ((rfv_if.vd_offset + 2) > VLENB) $info("Illegal 8bit write address: vd_offset = %d", rfv_if.vd_offset);
      if ((rfv_if.vd_offset) < rfv_if.vl) begin
        next_registers[rfv_if.vd][rfv_if.vd_offset]      = rfv_if.w_data[0][7:0]; 
      end
      if ((rfv_if.vd_offset + 1) < rfv_if.vl) begin
        next_registers[rfv_if.vd][rfv_if.vd_offset + 1]  = rfv_if.w_data[1][7:0]; 
      end
    end
  end



  always_comb begin : VS1_DATA
    rfv_if.vs1_data[0] = 32'hDED0DED0;
    rfv_if.vs1_data[1] = 32'hDED1DED1;

    if (rfv_if.vs1_offset <= rfv_if.vl) begin
      if (rfv_if.sew == SEW32) begin
        rfv_if.vs1_data[0] = registers[rfv_if.vs1][(rfv_if.vs1_offset << 2) +:4];
        rfv_if.vs1_data[1] = registers[rfv_if.vs1][((rfv_if.vs1_offset + 1) << 2) +:4];
      end else if (rfv_if.sew == SEW16) begin
        rfv_if.vs1_data[0] = {16'h0, registers[rfv_if.vs1][(rfv_if.vs1_offset << 1) +:2]};
        rfv_if.vs1_data[1] = {16'h0, registers[rfv_if.vs1][((rfv_if.vs1_offset + 1) << 1) +:2]};
      end else if (rfv_if.sew == SEW8) begin
        rfv_if.vs1_data[0] = {24'h0, registers[rfv_if.vs1][rfv_if.vs1_offset]};
        rfv_if.vs1_data[1] = {24'h0, registers[rfv_if.vs1][rfv_if.vs1_offset + 1]};
      end
    end
  end

  always_comb begin : VS2_DATA
    rfv_if.vs2_data[0] = 32'hDED0DED0;
    rfv_if.vs2_data[1] = 32'hDED1DED1;
    if (rfv_if.vs2_offset <= rfv_if.vl) begin
      if (rfv_if.sew == SEW32) begin
        rfv_if.vs2_data[0] = registers[rfv_if.vs2][(rfv_if.vs2_offset << 2) +:4];
        rfv_if.vs2_data[1] = registers[rfv_if.vs2][((rfv_if.vs2_offset + 1) << 2) +:4];
      end else if (rfv_if.sew == SEW16) begin
        rfv_if.vs2_data[0] = {16'h0, registers[rfv_if.vs2][(rfv_if.vs2_offset << 1) +:2]};
        rfv_if.vs2_data[1] = {16'h0, registers[rfv_if.vs2][((rfv_if.vs2_offset + 1) << 1) +:2]};
      end else if (rfv_if.sew == SEW8) begin
        rfv_if.vs2_data[0] = {24'h0, registers[rfv_if.vs2][rfv_if.vs2_offset]};
        rfv_if.vs2_data[1] = {24'h0, registers[rfv_if.vs2][rfv_if.vs2_offset + 1]};
      end
    end
  end

  always_comb begin : VS1_MASK 
    rfv_if.vs1_mask[0] = registers[rfv_if.vs1][rfv_if.vs1_offset >> 3][rfv_if.vs1_offset % 8];
    rfv_if.vs1_mask[1] = registers[rfv_if.vs1][(rfv_if.vs1_offset + 1) >> 3][(rfv_if.vs1_offset + 1) % 8];
  end
  
  always_comb begin : VS2_MASK 
    
    rfv_if.vs2_mask[0] = registers[rfv_if.vs2][rfv_if.vs2_offset >> 8][rfv_if.vs2_offset % 8];
    rfv_if.vs2_mask[1] = registers[rfv_if.vs2][(rfv_if.vs2_offset + 1) >> 8][(rfv_if.vs2_offset + 1) % 8];
  end
  // assign rfv_if.vs2_data = registers[rfv_if.vs2][7:0];

endmodule
