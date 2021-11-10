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
  parameter MAXLEN = NUM_REGS * 8;

  logic [6:0] vd1_start, vd2_start;
  // logic [6:0] vd1_end, vd2_end;

  logic [2:0] vs1_inner_offset;
  logic [2:0] vs2_inner_offset;
  logic [2:0] vs3_inner_offset;
  logic [2:0] vd_inner_offset;

  logic [1:0][3:0] vs1_outer_offset;
  logic [1:0][3:0] vs2_outer_offset;
  logic [1:0][3:0] vs3_outer_offset;
  logic [1:0][3:0] vd_outer_offset;  
  // set lower 2 bits to zero to round down instead of division
  offset_t vd_offset_lane1;
  offset_t vs1_offset_lane1;
  offset_t vs2_offset_lane1;
  offset_t vs3_offset_lane1;

  vreg_t [NUM_REGS-1:0] registers, next_registers;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
    end else begin
      registers <= next_registers;
    end
  end 

  assign vd_offset_lane1  = rfv_if.vd_offset  + 1;
  assign vs1_offset_lane1 = rfv_if.vs1_offset + 1;
  assign vs2_offset_lane1 = rfv_if.vs2_offset + 1;
  assign vs3_offset_lane1 = rfv_if.vs3_offset + 1;

  assign vd_inner_offset = rfv_if.eew == SEW32 ?  rfv_if.vd_offset[4:2] : 
                            rfv_if.eew == SEW16 ? rfv_if.vd_offset[5:3] : 
                                                  rfv_if.vd_offset[6:4];
  assign vs1_inner_offset = rfv_if.sew == SEW32 ? rfv_if.vs1_offset[4:2] : 
                            rfv_if.sew == SEW16 ? rfv_if.vs1_offset[5:3] : 
                                                  rfv_if.vs1_offset[6:4];
  assign vs2_inner_offset = rfv_if.vs2_sew == SEW32 ? rfv_if.vs2_offset[4:2] : 
                            rfv_if.vs2_sew == SEW16 ? rfv_if.vs2_offset[5:3] : 
                                                     rfv_if.vs2_offset[6:4];
  assign vs3_inner_offset = rfv_if.sew == SEW32 ? rfv_if.vs3_offset[4:2] : 
                            rfv_if.sew == SEW16 ? rfv_if.vs3_offset[5:3] : 
                                                  rfv_if.vs3_offset[6:4];



  assign vd_outer_offset[0] = rfv_if.eew == SEW32 ? {rfv_if.vd_offset[1:0], 2'b00} : 
                              rfv_if.eew == SEW16 ? {rfv_if.vd_offset[2:0], 1'b00} : 
                                                    rfv_if.vd_offset[3:0];
  assign vd_outer_offset[1] = rfv_if.eew == SEW32 ? {vd_offset_lane1[1:0], 2'b00} : 
                              rfv_if.eew == SEW16 ? {vd_offset_lane1[2:0], 1'b00} : 
                                                    vd_offset_lane1[3:0];
                                                    

  assign vs1_outer_offset[0] = rfv_if.sew == SEW32 ? {rfv_if.vs1_offset[1:0], 2'b00} : 
                               rfv_if.sew == SEW16 ? {rfv_if.vs1_offset[2:0], 1'b00} : 
                                                     rfv_if.vs1_offset[3:0];
  assign vs1_outer_offset[1] = rfv_if.sew == SEW32 ? {vd_offset_lane1[1:0], 2'b00} : 
                               rfv_if.sew == SEW16 ? {vd_offset_lane1[2:0], 1'b00} : 
                                                     vd_offset_lane1[3:0];
                                                    
                                                    
  assign vs2_outer_offset[0] = rfv_if.vs2_sew == SEW32 ? {rfv_if.vs2_offset[1:0], 2'b00} : 
                               rfv_if.vs2_sew == SEW16 ? {rfv_if.vs2_offset[2:0], 1'b00} : 
                                                         rfv_if.vs2_offset[3:0];
  assign vs2_outer_offset[1] = rfv_if.vs2_sew == SEW32 ? {vs2_offset_lane1[1:0], 2'b00} : 
                               rfv_if.vs2_sew == SEW16 ? {vs2_offset_lane1[2:0], 1'b00} : 
                                                         vs2_offset_lane1[3:0];
                                                    
                                                    
  assign vs3_outer_offset[0] = rfv_if.sew == SEW32 ? {rfv_if.vs3_offset[1:0], 2'b00} : 
                               rfv_if.sew == SEW16 ? {rfv_if.vs3_offset[2:0], 1'b00} : 
                                                     rfv_if.vs3_offset[3:0];
  assign vs3_outer_offset[1] = rfv_if.sew == SEW32 ? {vs3_offset_lane1[1:0], 2'b00} : 
                               rfv_if.sew == SEW16 ? {vs3_offset_lane1[2:0], 1'b00} : 
                                                     vs3_offset_lane1[3:0];
  

  always_comb begin : WRITE_DATA
    next_registers = registers;
    if (rfv_if.wen & rfv_if.eew == SEW32) begin //4 byte
      if ((rfv_if.vd_offset + 2) << 2 > MAXLEN) $info("Illegal 32bit write address: vd_offset = %d", rfv_if.vd_offset);
      if (rfv_if.vd_offset < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][vd_outer_offset[0] +:4]       = rfv_if.w_data[0][31:0];
      end
      if (rfv_if.vd_offset + 1 < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][vd_outer_offset[1] +:4] = rfv_if.w_data[1][31:0];
      end
    end else if (rfv_if.wen & rfv_if.eew == SEW16) begin //2 byte
      if ((rfv_if.vd_offset + 2) << 1 > MAXLEN)  $info("Illegal 16bit write address: vd_offset = %d", rfv_if.vd_offset);
      if (rfv_if.vd_offset < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][vd_outer_offset[0] +:2]       = rfv_if.w_data[0][15:0]; 
      end
      if ((rfv_if.vd_offset + 1) < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][vd_outer_offset[1] +:2] = rfv_if.w_data[1][15:0];
      end
    end else if (rfv_if.wen & rfv_if.eew == SEW8) begin //1 byte
      if ((rfv_if.vd_offset + 2) > MAXLEN) $info("Illegal 8bit write address: vd_offset = %d", rfv_if.vd_offset);
      if ((rfv_if.vd_offset) < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][vd_outer_offset[0]]      = rfv_if.w_data[0][7:0]; 
      end
      if ((rfv_if.vd_offset + 1) < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][vd_outer_offset[1]]  = rfv_if.w_data[1][7:0]; 
      end
    end
  end

  always_comb begin : VS1_DATA
    rfv_if.vs1_data[0] = 32'hDED0DED0;
    rfv_if.vs1_data[1] = 32'hDED1DED1;

    if (rfv_if.vs1_offset <= rfv_if.vl) begin
      if (rfv_if.sew == SEW32) begin
        rfv_if.vs1_data[0] = registers[rfv_if.vs1 + vs1_inner_offset][vs1_outer_offset[0] +:4];
        rfv_if.vs1_data[1] = registers[rfv_if.vs1 + vs1_inner_offset][vs1_outer_offset[1] +:4];
      end else if (rfv_if.sew == SEW16) begin
        rfv_if.vs1_data[0] = {16'h0, registers[rfv_if.vs1 + vs1_inner_offset][vs1_outer_offset[0] +:2]};
        rfv_if.vs1_data[1] = {16'h0, registers[rfv_if.vs1 + vs1_inner_offset][vs1_outer_offset[1] +:2]};
      end else if (rfv_if.sew == SEW8) begin
        rfv_if.vs1_data[0] = {24'h0, registers[rfv_if.vs1 + vs1_inner_offset][vs1_outer_offset[0]]};
        rfv_if.vs1_data[1] = {24'h0, registers[rfv_if.vs1 + vs1_inner_offset][vs1_outer_offset[1]]};
      end
    end
  end

  always_comb begin : VS2_DATA
    rfv_if.vs2_data[0] = 32'hDED0DED0;
    rfv_if.vs2_data[1] = 32'hDED1DED1;
    if (rfv_if.vs2_offset <= rfv_if.vl) begin
      if (rfv_if.vs2_sew == SEW32) begin
        rfv_if.vs2_data[0] = registers[rfv_if.vs2 + vs2_inner_offset][vs2_outer_offset[0] +:4];
        rfv_if.vs2_data[1] = registers[rfv_if.vs2 + vs2_inner_offset][vs2_outer_offset[1] +:4];
      end else if (rfv_if.vs2_sew == SEW16) begin
        rfv_if.vs2_data[0] = {16'h0, registers[rfv_if.vs2 + vs2_inner_offset][vs2_outer_offset[0] +:2]};
        rfv_if.vs2_data[1] = {16'h0, registers[rfv_if.vs2 + vs2_inner_offset][vs2_outer_offset[1] +:2]};
      end else if (rfv_if.vs2_sew == SEW8) begin
        rfv_if.vs2_data[0] = {24'h0, registers[rfv_if.vs2 + vs2_inner_offset][vs2_outer_offset[0]]};
        rfv_if.vs2_data[1] = {24'h0, registers[rfv_if.vs2 + vs2_inner_offset][vs2_outer_offset[1]]};
      end
    end
  end

   always_comb begin : VS3_DATA
    rfv_if.vs3_data[0] = 32'hDED0DED0;
    rfv_if.vs3_data[1] = 32'hDED1DED1;
    if (rfv_if.vs3_offset <= rfv_if.vl) begin
      if (rfv_if.sew == SEW32) begin
        rfv_if.vs3_data[0] = registers[rfv_if.vs3 + vs3_inner_offset][vs3_outer_offset[0] +:4];
        rfv_if.vs3_data[1] = registers[rfv_if.vs3 + vs3_inner_offset][vs3_outer_offset[1] +:4];
      end else if (rfv_if.sew == SEW16) begin
        rfv_if.vs3_data[0] = {16'h0, registers[rfv_if.vs3 + vs3_inner_offset][(vs3_outer_offset[0]) +:2]};
        rfv_if.vs3_data[1] = {16'h0, registers[rfv_if.vs3 + vs3_inner_offset][(vs3_outer_offset[1]) +:2]};
      end else if (rfv_if.sew == SEW8) begin
        rfv_if.vs3_data[0] = {24'h0, registers[rfv_if.vs3 + vs3_inner_offset][vs3_outer_offset[0]]};
        rfv_if.vs3_data[1] = {24'h0, registers[rfv_if.vs3 + vs3_inner_offset][vs3_outer_offset[1]]};
      end
    end
  end

  always_comb begin : VS1_MASK 
    rfv_if.vs1_mask[0] = registers[rfv_if.vs1][rfv_if.vs1_offset >> 3][rfv_if.vs1_offset [2:0]];
    rfv_if.vs1_mask[1] = registers[rfv_if.vs1][vs1_offset_lane1  >> 3][vs1_offset_lane1  [2:0]];
  end
  
  always_comb begin : VS2_MASK 
    rfv_if.vs2_mask[0] = registers[rfv_if.vs2][rfv_if.vs2_offset >> 8][rfv_if.vs2_offset [2:0]];
    rfv_if.vs2_mask[1] = registers[rfv_if.vs2][vs2_offset_lane1  >> 8][vs2_offset_lane1  [2:0]];
  end

  always_comb begin : VS3_MASK 
    rfv_if.vs3_mask[0] = registers[rfv_if.vs3][rfv_if.vs3_offset >> 8][rfv_if.vs3_offset [2:0]];
    rfv_if.vs3_mask[1] = registers[rfv_if.vs3][vs3_offset_lane1  >> 8][vs3_offset_lane1  [2:0]];
  end


endmodule
