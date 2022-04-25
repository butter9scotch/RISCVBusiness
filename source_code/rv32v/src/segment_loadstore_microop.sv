/*
*   Copyright 2021 Purdue University
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
*   Filename:     segment_loadstore_microop.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 4/25/2022
*   Description:  Microop buffer for segmented load store instruction
*                  
*/

import rv32i_types_pkg::*;

module segment_loadstore_microop (
  input logic CLK, nRST,
  input logic [31:0] instr,
  input logic shift_ena,
  input logic is_vector,
  input vlmul_t lmul,
  input sew_t sew,
  output logic busy,
  output logic segment_ena,
  output logic [2:0] nf_counter,
  output logic [31:0] segment_instr,
  output logic [31:0] base_address_offset
);

  logic is_segment, segment_unit, segment_strided, segment_index, indexed;
  logic load_ena, is_segment_reg, next_busy;
  logic [1:0] mop;
  logic [2:0] nf, next_nf_counter, eew, next_eew, eew_reg;
  logic [4:0] rd_offset, rd, rd_plus1, rd_plus2, rd_plus3, rd_plus4, rd_plus5, rd_plus6, rd_plus7, rd_plus8;
  logic [4:0] base_addr;
  //logic [223:0] addr_off_reg, next_addr_off_reg; // 7 * 32bit
  logic [255:0] buffer, next_buffer; // 7 * 32bit
  word_t instr_plus0, instr_plus1, instr_plus2, instr_plus3, instr_plus4, instr_plus5, instr_plus6, instr_plus7, instr_plus8, address_offset, next_base_address_offset;
  vlmul_t sew_to_eew;

  assign nf = instr[31:29];
  assign rd = instr[11:7];
  assign mop = instr[27:26];
  assign base_addr = instr[19:15];
  assign eew = width_t'(instr[14:12]);
  assign indexed = (mop == 2'b01) || (mop == 2'b11);
  assign rd_plus1 = rd + rd_offset;
  assign rd_plus2 = rd_plus1 + rd_offset;
  assign rd_plus3 = rd_plus2 + rd_offset;
  assign rd_plus4 = rd_plus3 + rd_offset;
  assign rd_plus5 = rd_plus4 + rd_offset;
  assign rd_plus6 = rd_plus5 + rd_offset;
  assign rd_plus7 = rd_plus6 + rd_offset;
  assign instr_plus0 = {3'd0, instr[28:0]};
  assign instr_plus1 = {3'd0, instr[28:12], rd_plus1, instr[6:0]};
  assign instr_plus2 = {3'd0, instr[28:12], rd_plus2, instr[6:0]};
  assign instr_plus3 = {3'd0, instr[28:12], rd_plus3, instr[6:0]};
  assign instr_plus4 = {3'd0, instr[28:12], rd_plus4, instr[6:0]};
  assign instr_plus5 = {3'd0, instr[28:12], rd_plus5, instr[6:0]};
  assign instr_plus6 = {3'd0, instr[28:12], rd_plus6, instr[6:0]};
  assign instr_plus7 = {3'd0, instr[28:12], rd_plus7, instr[6:0]};
  assign is_segment = (nf != 3'd0) & (instr[24:20] != 5'b01000) & is_vector;
  assign load_ena = is_segment & ~is_segment_reg;
  assign segment_instr = load_ena ? {3'd0, instr[28:0]} : buffer[31:0];
  assign segment_ena = is_segment | busy;

  always_comb begin
    case(lmul)
      LMUL1: rd_offset = 1;
      LMUL2: rd_offset = 2;
      LMUL4: rd_offset = 4;
      LMUL8: rd_offset = 8;
      default: rd_offset = 1;
    endcase
  end

  always_comb begin
    case(sew)
      SEW8: sew_to_eew = WIDTH8;
      SEW16: sew_to_eew = WIDTH16;
      SEW32: sew_to_eew = WIDTH32;
      default: sew_to_eew = WIDTH8;
    endcase
  end

  always_comb begin
    case(eew_reg)
      WIDTH8: address_offset = 1;
      WIDTH16: address_offset = 2;
      WIDTH32: address_offset = 4;
      default: address_offset = 1;
    endcase
  end

  always_ff @(posedge CLK, negedge nRST) begin 
    if (~nRST) begin
      is_segment_reg <= 0;
    end else begin
      is_segment_reg <= is_segment;
    end 
  end 

  always_ff @(posedge CLK, negedge nRST) begin 
    if (~nRST) begin
      buffer <= 0;
      nf_counter <= '0;
      busy <= 0;
      base_address_offset <= 0;
      eew_reg <= 0;
    end else begin
      buffer <= next_buffer;
      nf_counter <= next_nf_counter;
      busy <= next_busy;
      base_address_offset <= next_base_address_offset;
      eew_reg <= next_eew;
    end 
  end 

  always_comb begin
    next_buffer = buffer;
    next_nf_counter = nf_counter;
    next_busy = busy;
    next_base_address_offset = base_address_offset;
    next_eew = eew_reg;
    if (busy & shift_ena) begin
      next_buffer = nf_counter == 1 ? '0: buffer >> 32;
      next_nf_counter = nf_counter - 1;
      next_busy = nf_counter != 1;
      next_base_address_offset = nf_counter == 1 ? '0: base_address_offset + address_offset;
      //next_eew = 0;
    end else if (load_ena) begin
      next_buffer = {instr_plus7, instr_plus6, instr_plus5, instr_plus4, instr_plus3, instr_plus2, instr_plus1, instr_plus0};
      next_nf_counter = nf + 1; // TODO: check 
      next_busy = 1;
      next_base_address_offset = 0;
      next_eew = indexed ? sew_to_eew : eew;
    end
  end

endmodule
