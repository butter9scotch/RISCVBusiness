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
  parameter MAXLEN = VLENB * 8;

  logic [6:0] vd1_start, vd2_start;
  logic [6:0] vd1_end, vd2_end;

  logic [2:0] vs1_inner_offset;
  logic [2:0] vs2_inner_offset;
  logic [2:0] vs3_inner_offset;
  logic [2:0] vd_inner_offset;

  logic [3:0][1:0] vs1_outer_offset;
  logic [3:0][1:0] vs2_outer_offset;
  logic [3:0][1:0] vs3_outer_offset;
  logic [3:0][1:0] vd_outer_offset;

  sew_t effective_rs2_sew;
  
  // set lower 2 bits to zero to round down instead of division

  vreg_t [NUM_REGS-1:0] registers, next_registers;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
    end else begin
      registers <= next_registers;
    end
  end 

  always_comb begin
    if (rfv_if.rs2_widen) begin
      case(rfv_if.sew)
        SEW32, SEW16: SEW32;
        SEW8: SEW16;
      endcase
    end else begin
      effective_rs2_sew = rfv_if.sew;
    end
  end
  assign effective_rs2_sew = rfv_if.rs2_widen ? 

  assign vd_outer_offset[0] = rfv_if.eew == SEW32 ? (rfv_if.vd_offset << 2) : 
                              rfv_if.eew == SEW16 ? (rfv_if.vd_offset << 1) : 
                                                    (rfv_if.vd_offset);
  assign vd_outer_offset[1] = rfv_if.eew == SEW32 ? ((rfv_if.vd_offset + 1) << 2) : 
                              rfv_if.eew == SEW16 ? ((rfv_if.vd_offset + 1) << 1) : 
                                                    ((rfv_if.vd_offset + 1));
                                                    

  assign vs1_outer_offset[0] = rfv_if.sew == SEW32 ? (rfv_if.vs1_offset << 2) : 
                               rfv_if.sew == SEW16 ? (rfv_if.vs1_offset << 1) : 
                                                     (rfv_if.vs1_offset);
  assign vs1_outer_offset[1] = rfv_if.sew == SEW32 ? ((rfv_if.vs1_offset + 1) << 2) : 
                               rfv_if.sew == SEW16 ? ((rfv_if.vs1_offset + 1) << 1) : 
                                                     ((rfv_if.vs1_offset + 1));
                                                    
                                                    
  assign vs2_outer_offset[0] = effective_rs2_sew == SEW32 ? (rfv_if.vs2_offset << 2) : 
                               effective_rs2_sew == SEW16 ? (rfv_if.vs2_offset << 1) : 
                                                     (rfv_if.vs2_offset);
  assign vs2_outer_offset[1] = effective_rs2_sew == SEW32 ? ((rfv_if.vs2_offset + 1) << 2) : 
                               effective_rs2_sew == SEW16 ? ((rfv_if.vs2_offset + 1) << 1) : 
                                                     ((rfv_if.vs2_offset + 1));
                                                    
                                                    
  assign vs3_outer_offset[0] = rfv_if.sew == SEW32 ? (rfv_if.vs3_offset << 2) : 
                               rfv_if.sew == SEW16 ? (rfv_if.vs3_offset << 1) : 
                                                     (rfv_if.vs3_offset);
  assign vs3_outer_offset[1] = rfv_if.sew == SEW32 ? ((rfv_if.vs3_offset + 1) << 2) : 
                               rfv_if.sew == SEW16 ? ((rfv_if.vs3_offset + 1) << 1) : 
                                                     ((rfv_if.vs3_offset + 1));
  

  always_comb begin : WRITE_DATA
    next_registers = registers;
    if (rfv_if.wen & rfv_if.eew == SEW32) begin //4 byte
      if ((rfv_if.vd_offset + 2) << 2 > MAXLEN) $info("Illegal 32bit write address: vd_offset = %d", rfv_if.vd_offset);
      if (rfv_if.vd_offset < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][(rfv_if.vd_offset << 2) +:4]       = rfv_if.w_data[0][31:0];
      end
      if (rfv_if.vd_offset + 1 < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][((rfv_if.vd_offset + 1) << 2) +:4] = rfv_if.w_data[1][31:0];
      end
    end else if (rfv_if.wen & rfv_if.eew == SEW16) begin //2 byte
      if ((rfv_if.vd_offset + 2) << 1 > MAXLEN)  $info("Illegal 16bit write address: vd_offset = %d", rfv_if.vd_offset);
      if (rfv_if.vd_offset < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][(rfv_if.vd_offset << 1) +:2]       = rfv_if.w_data[0][15:0]; 
      end
      if ((rfv_if.vd_offset + 1) < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][((rfv_if.vd_offset + 1) << 1) +:2] = rfv_if.w_data[1][15:0];
      end
    end else if (rfv_if.wen & rfv_if.eew == SEW8) begin //1 byte
      if ((rfv_if.vd_offset + 2) > MAXLEN) $info("Illegal 8bit write address: vd_offset = %d", rfv_if.vd_offset);
      if ((rfv_if.vd_offset) < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][rfv_if.vd_offset]      = rfv_if.w_data[0][7:0]; 
      end
      if ((rfv_if.vd_offset + 1) < rfv_if.vl) begin
        next_registers[rfv_if.vd + vd_inner_offset][rfv_if.vd_offset + 1]  = rfv_if.w_data[1][7:0]; 
      end
    end
  end

  always_comb begin : VS1_DATA
    rfv_if.vs1_data[0] = 32'hDED0DED0;
    rfv_if.vs1_data[1] = 32'hDED1DED1;

    if (rfv_if.vs1_offset <= rfv_if.vl) begin
      if (rfv_if.sew == SEW32) begin
        rfv_if.vs1_data[0] = registers[rfv_if.vs1 + vs1_inner_offset][(rfv_if.vs1_offset << 2) +:4];
        rfv_if.vs1_data[1] = registers[rfv_if.vs1 + vs1_inner_offset][((rfv_if.vs1_offset + 1) << 2) +:4];
      end else if (rfv_if.sew == SEW16) begin
        rfv_if.vs1_data[0] = {16'h0, registers[rfv_if.vs1 + vs1_inner_offset][(rfv_if.vs1_offset << 1) +:2]};
        rfv_if.vs1_data[1] = {16'h0, registers[rfv_if.vs1 + vs1_inner_offset][((rfv_if.vs1_offset + 1) << 1) +:2]};
      end else if (rfv_if.sew == SEW8) begin
        rfv_if.vs1_data[0] = {24'h0, registers[rfv_if.vs1 + vs1_inner_offset][rfv_if.vs1_offset]};
        rfv_if.vs1_data[1] = {24'h0, registers[rfv_if.vs1 + vs1_inner_offset][rfv_if.vs1_offset + 1]};
      end
    end
  end

  always_comb begin : VS2_DATA
    rfv_if.vs2_data[0] = 32'hDED0DED0;
    rfv_if.vs2_data[1] = 32'hDED1DED1;
    if (rfv_if.vs2_offset <= rfv_if.vl) begin
      if (rfv_if.sew == SEW32) begin
        rfv_if.vs2_data[0] = registers[rfv_if.vs2 + vs2_inner_offset][(rfv_if.vs2_offset << 2) +:4];
        rfv_if.vs2_data[1] = registers[rfv_if.vs2 + vs2_inner_offset][((rfv_if.vs2_offset + 1) << 2) +:4];
      end else if (rfv_if.sew == SEW16) begin
        rfv_if.vs2_data[0] = {16'h0, registers[rfv_if.vs2 + vs2_inner_offset][(rfv_if.vs2_offset << 1) +:2]};
        rfv_if.vs2_data[1] = {16'h0, registers[rfv_if.vs2 + vs2_inner_offset][((rfv_if.vs2_offset + 1) << 1) +:2]};
      end else if (rfv_if.sew == SEW8) begin
        rfv_if.vs2_data[0] = {24'h0, registers[rfv_if.vs2 + vs2_inner_offset][rfv_if.vs2_offset]};
        rfv_if.vs2_data[1] = {24'h0, registers[rfv_if.vs2 + vs2_inner_offset][rfv_if.vs2_offset + 1]};
      end
    end
  end

   always_comb begin : VS3_DATA
    rfv_if.vs3_data[0] = 32'hDED0DED0;
    rfv_if.vs3_data[1] = 32'hDED1DED1;
    if (rfv_if.vs3_offset <= rfv_if.vl) begin
      if (rfv_if.sew == SEW32) begin
        rfv_if.vs3_data[0] = registers[rfv_if.vs3 + vs3_inner_offset][(rfv_if.vs3_offset << 2) +:4];
        rfv_if.vs3_data[1] = registers[rfv_if.vs3 + vs3_inner_offset][((rfv_if.vs3_offset + 1) << 2) +:4];
      end else if (rfv_if.sew == SEW16) begin
        rfv_if.vs3_data[0] = {16'h0, registers[rfv_if.vs3 + vs3_inner_offset][(rfv_if.vs3_offset << 1) +:2]};
        rfv_if.vs3_data[1] = {16'h0, registers[rfv_if.vs3 + vs3_inner_offset][((rfv_if.vs3_offset + 1) << 1) +:2]};
      end else if (rfv_if.sew == SEW8) begin
        rfv_if.vs3_data[0] = {24'h0, registers[rfv_if.vs3 + vs3_inner_offset][rfv_if.vs3_offset]};
        rfv_if.vs3_data[1] = {24'h0, registers[rfv_if.vs3 + vs3_inner_offset][rfv_if.vs3_offset + 1]};
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

  always_comb begin : VS3_MASK 
    rfv_if.vs3_mask[0] = registers[rfv_if.vs3][rfv_if.vs3_offset >> 8][rfv_if.vs3_offset % 8];
    rfv_if.vs3_mask[1] = registers[rfv_if.vs3][(rfv_if.vs3_offset + 1) >> 8][(rfv_if.vs3_offset + 1) % 8];
  end

  //brute force muxes to avoid division
  
  if (rfv_if.sew == SEW32) begin : VD_INNER_INDEX_OFFSET
    if      (rfv_if.vd_offset >=28)   vd_inner_offset = 7;
    else if (rfv_if.vd_offset >= 24)  vd_inner_offset = 6;
    else if (rfv_if.vd_offset >= 20)  vd_inner_offset = 5;
    else if (rfv_if.vd_offset >= 16)  vd_inner_offset = 4;
    else if (rfv_if.vd_offset >= 12)  vd_inner_offset = 3;
    else if (rfv_if.vd_offset >= 8)   vd_inner_offset = 2;
    else if (rfv_if.vd_offset >= 4)   vd_inner_offset = 1;
    else if (rfv_if.vd_offset >= 0)   vd_inner_offset = 0;
    else begin
      $error("vd Illegal offset, SEW 32")
    end
  end else if (rfv_if.sew == SEW16) begin
    if      (rfv_if.vd_offset >=56)   vd_inner_offset = 7;
    else if (rfv_if.vd_offset >= 48)  vd_inner_offset = 6;
    else if (rfv_if.vd_offset >= 40)  vd_inner_offset = 5;
    else if (rfv_if.vd_offset >= 32)  vd_inner_offset = 4;
    else if (rfv_if.vd_offset >= 24)  vd_inner_offset = 3;
    else if (rfv_if.vd_offset >= 16)  vd_inner_offset = 2;
    else if (rfv_if.vd_offset >= 8)   vd_inner_offset = 1;
    else if (rfv_if.vd_offset >= 0)   vd_inner_offset = 0;
    else begin
      $error("vd Illegal offset, SEW 16")
    end
  end else if (rfv_if.sew == SEW8)  begin
    if      (rfv_if.vd_offset >=112)  vd_inner_offset = 7;
    else if (rfv_if.vd_offset >= 96)  vd_inner_offset = 6;
    else if (rfv_if.vd_offset >= 80)  vd_inner_offset = 5;
    else if (rfv_if.vd_offset >= 64)  vd_inner_offset = 4;
    else if (rfv_if.vd_offset >= 48)  vd_inner_offset = 3;
    else if (rfv_if.vd_offset >= 32)  vd_inner_offset = 2;
    else if (rfv_if.vd_offset >= 16)  vd_inner_offset = 1;
    else if (rfv_if.vd_offset >= 0)   vd_inner_offset = 0;
    else begin
      $error("vd Illegal offset, SEW 8")
    end
  end

    if (rfv_if.sew == SEW32) begin : VS1_INNER_INDEX_OFFSET_SEW32
    if      (rfv_if.vs1_offset >=28)   vs1_inner_offset = 7;
    else if (rfv_if.vs1_offset >= 24)  vs1_inner_offset = 6;
    else if (rfv_if.vs1_offset >= 20)  vs1_inner_offset = 5;
    else if (rfv_if.vs1_offset >= 16)  vs1_inner_offset = 4;
    else if (rfv_if.vs1_offset >= 12)  vs1_inner_offset = 3;
    else if (rfv_if.vs1_offset >= 8)   vs1_inner_offset = 2;
    else if (rfv_if.vs1_offset >= 4)   vs1_inner_offset = 1;
    else if (rfv_if.vs1_offset >= 0)   vs1_inner_offset = 0;
    else begin
      $error("vs1: Illegal offset, SEW 32")
    end
  end else if (rfv_if.sew == SEW16) begin : VS1_INNER_INDEX_OFFSET_SEW16
    if      (rfv_if.vs1_offset >=56)   vs1_inner_offset = 7;
    else if (rfv_if.vs1_offset >= 48)  vs1_inner_offset = 6;
    else if (rfv_if.vs1_offset >= 40)  vs1_inner_offset = 5;
    else if (rfv_if.vs1_offset >= 32)  vs1_inner_offset = 4;
    else if (rfv_if.vs1_offset >= 24)  vs1_inner_offset = 3;
    else if (rfv_if.vs1_offset >= 16)  vs1_inner_offset = 2;
    else if (rfv_if.vs1_offset >= 8)   vs1_inner_offset = 1;
    else if (rfv_if.vs1_offset >= 0)   vs1_inner_offset = 0;
    else begin
      $error("vs1: Illegal offset, SEW 16")
    end
  end else if (rfv_if.sew == SEW8)  begin : VS1_INNER_INDEX_OFFSET_SEW8
    if      (rfv_if.vs1_offset >=112)  vs1_inner_offset = 7;
    else if (rfv_if.vs1_offset >= 96)  vs1_inner_offset = 6;
    else if (rfv_if.vs1_offset >= 80)  vs1_inner_offset = 5;
    else if (rfv_if.vs1_offset >= 64)  vs1_inner_offset = 4;
    else if (rfv_if.vs1_offset >= 48)  vs1_inner_offset = 3;
    else if (rfv_if.vs1_offset >= 32)  vs1_inner_offset = 2;
    else if (rfv_if.vs1_offset >= 16)  vs1_inner_offset = 1;
    else if (rfv_if.vs1_offset >= 0)   vs1_inner_offset = 0;
    else begin
      $error("vs1: Illegal offset, SEW 8")
    end
  end

  //Vs2 signals

  if (rfv_if.sew == SEW32) begin  : Vs2_INNER_INDEX_OFFSET_SEW32
    if      (rfv_if.vs2_offset >=28)   vs2_inner_offset = 7;
    else if (rfv_if.vs2_offset >= 24)  vs2_inner_offset = 6;
    else if (rfv_if.vs2_offset >= 20)  vs2_inner_offset = 5;
    else if (rfv_if.vs2_offset >= 16)  vs2_inner_offset = 4;
    else if (rfv_if.vs2_offset >= 12)  vs2_inner_offset = 3;
    else if (rfv_if.vs2_offset >= 8)   vs2_inner_offset = 2;
    else if (rfv_if.vs2_offset >= 4)   vs2_inner_offset = 1;
    else if (rfv_if.vs2_offset >= 0)   vs2_inner_offset = 0;
    else begin
      $error("Illegal offset, SEW 32")
    end
  end else if (rfv_if.sew == SEW16) begin : Vs2_INNER_INDEX_OFFSET_SEW16
    if      (rfv_if.vs2_offset >=56)   vs2_inner_offset = 7;
    else if (rfv_if.vs2_offset >= 48)  vs2_inner_offset = 6;
    else if (rfv_if.vs2_offset >= 40)  vs2_inner_offset = 5;
    else if (rfv_if.vs2_offset >= 32)  vs2_inner_offset = 4;
    else if (rfv_if.vs2_offset >= 24)  vs2_inner_offset = 3;
    else if (rfv_if.vs2_offset >= 16)  vs2_inner_offset = 2;
    else if (rfv_if.vs2_offset >= 8)   vs2_inner_offset = 1;
    else if (rfv_if.vs2_offset >= 0)   vs2_inner_offset = 0;
    else begin
      $error("Illegal offset, SEW 16")
    end
  end else if (rfv_if.sew == SEW8)  begin : Vs2_INNER_INDEX_OFFSET_SEW8
    if      (rfv_if.vs2_offset >=112)  vs2_inner_offset = 7;
    else if (rfv_if.vs2_offset >= 96)  vs2_inner_offset = 6;
    else if (rfv_if.vs2_offset >= 80)  vs2_inner_offset = 5;
    else if (rfv_if.vs2_offset >= 64)  vs2_inner_offset = 4;
    else if (rfv_if.vs2_offset >= 48)  vs2_inner_offset = 3;
    else if (rfv_if.vs2_offset >= 32)  vs2_inner_offset = 2;
    else if (rfv_if.vs2_offset >= 16)  vs2_inner_offset = 1;
    else if (rfv_if.vs2_offset >= 0)   vs2_inner_offset = 0;
    else begin
      $error("Illegal offset, SEW 8")
    end
  end

  //vs3 signals

  if (rfv_if.sew == SEW32) begin
    if      (rfv_if.vs3_offset >=28)   vs3_inner_offset = 7;
    else if (rfv_if.vs3_offset >= 24)  vs3_inner_offset = 6;
    else if (rfv_if.vs3_offset >= 20)  vs3_inner_offset = 5;
    else if (rfv_if.vs3_offset >= 16)  vs3_inner_offset = 4;
    else if (rfv_if.vs3_offset >= 12)  vs3_inner_offset = 3;
    else if (rfv_if.vs3_offset >= 8)   vs3_inner_offset = 2;
    else if (rfv_if.vs3_offset >= 4)   vs3_inner_offset = 1;
    else if (rfv_if.vs3_offset >= 0)   vs3_inner_offset = 0;
    else begin
      $error("Illegal offset, SEW 32")
    end
  end else if (rfv_if.sew == SEW16) begin
    if      (rfv_if.vs3_offset >=56)   vs3_inner_offset = 7;
    else if (rfv_if.vs3_offset >= 48)  vs3_inner_offset = 6;
    else if (rfv_if.vs3_offset >= 40)  vs3_inner_offset = 5;
    else if (rfv_if.vs3_offset >= 32)  vs3_inner_offset = 4;
    else if (rfv_if.vs3_offset >= 24)  vs3_inner_offset = 3;
    else if (rfv_if.vs3_offset >= 16)  vs3_inner_offset = 2;
    else if (rfv_if.vs3_offset >= 8)   vs3_inner_offset = 1;
    else if (rfv_if.vs3_offset >= 0)   vs3_inner_offset = 0;
    else begin
      $error("Illegal offset, SEW 16")
    end
  end else if (rfv_if.sew == SEW8)  begin
    if      (rfv_if.vs3_offset >=112)  vs3_inner_offset = 7;
    else if (rfv_if.vs3_offset >= 96)  vs3_inner_offset = 6;
    else if (rfv_if.vs3_offset >= 80)  vs3_inner_offset = 5;
    else if (rfv_if.vs3_offset >= 64)  vs3_inner_offset = 4;
    else if (rfv_if.vs3_offset >= 48)  vs3_inner_offset = 3;
    else if (rfv_if.vs3_offset >= 32)  vs3_inner_offset = 2;
    else if (rfv_if.vs3_offset >= 16)  vs3_inner_offset = 1;
    else if (rfv_if.vs3_offset >= 0)   vs3_inner_offset = 0;
    else begin
      $error("Illegal offset, SEW 8")
    end
  end

endmodule
