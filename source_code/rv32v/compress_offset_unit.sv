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
*   Filename:     compress_offset_unit.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 12/6/2021
*   Description:  Calculate woffset for vcompress instr
*                  
*/

`include "compress_offset_unit_if.vh"

module compress_offset_unit(
  input logic CLK, nRST,
  compress_offset_unit_if.compress_offset_unit cou_if
);

  import rv32v_types_pkg::*;

  // TODO: assign mask2bit logics

  offset_t next_woffset0, next_woffset1, prev_woffset, cout;
  logic [1:0] mask_bit_checking, mask2bit;
  logic done_mask1; // 0: Checking mask bit 1, 1: Checking mask bit 0

  assign mask_bit_checking = done_mask1 ? ~mask2bit : mask2bit;
  assign cou_if.checking_mask0_1 = ~done_mask1;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      cou_if.woffset0 <= '0;
      cou_if.woffset1 <= '0;
      prev_woffset <= '0;
      cou_if.busy <= '0;
    end else if (done_mask1 && cou_if.done) begin // When element counter reaches 2*VL
      cou_if.woffset0 <= '0;
      cou_if.woffset1 <= '0;
      prev_woffset <= '0;
      cou_if.busy <= '0; 
    end else if (cou_if.ena) begin
      cou_if.woffset0 <= next_woffset0;
      cou_if.woffset1 <= next_woffset1;
      prev_woffset <= cou_if.woffset1 + cout;
      cou_if.busy <= 1;
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      done_mask1 <= 0; 
    end else if (cou_if.busy && cou_if.done) begin // When element counter reaches VL and 2*VL
      done_mask1 <= done_mask1 + 1;
    end
  end

  always_comb begin
    next_woffset0 = '0;
    next_woffset1 = '0;
    case(mask_bit_checking)
      2'b00: 
      begin
        next_woffset0 = prev_woffset;
        next_woffset1 = prev_woffset;
        cout = 0; 
      end
      2'b01: 
      begin
        next_woffset0 = prev_woffset;
        next_woffset1 = prev_woffset + 1;
        cout = 0; 
      end
      2'b10: 
      begin
        next_woffset0 = prev_woffset;
        next_woffset1 = prev_woffset;
        cout = 1; 
      end
      2'b11: 
      begin
        next_woffset0 = prev_woffset;
        next_woffset1 = prev_woffset + 1;
        cout = 1; 
      end
    endcase
  end

  assign cou_if.wen = mask_bit_checking;

endmodule
