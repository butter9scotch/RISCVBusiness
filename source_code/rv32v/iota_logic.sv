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
*   Filename:     iota_logic.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 11/13/2021
*   Description:  Support iota instr (in mask subset)
*/

`include "iota_logic_if.vh"

module iota_logic (
  input logic CLK, nRST,
  iota_logic_if.iota_logic iif
);    

  import rv32v_types_pkg::*;

  logic [63:0] temp;
  logic [31:0] out1, out2, out3, out4, out5, out6, out7, out8;
  logic [31:0] prev_res, next_prev_res, mask_reg, next_mask_reg, count, next_count;
  logic prev_mask, next_prev_mask, busy_reg, next_busy;
  logic max;

  assign temp = count == 0 ? iif.mask_bits : mask_reg;
  assign out1 = count == 0 ? 0 : prev_mask + prev_res;
  assign out2 = out1 + temp[0];
  assign out3 = out2 + temp[1];
  assign out4 = out3 + temp[2];
  assign out5 = out4 + temp[3];
  assign out6 = out5 + temp[4];
  assign out7 = out6 + temp[5];
  assign out8 = out7 + temp[6];
  assign max  = (count == iif.max) | (count == 64);
  // assign iif.busy = (iif.start | busy_reg) & ~max;
  assign iif.busy = 0;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      mask_reg <= '0;
      count <= '0;
      prev_res <= '0;
      prev_mask <= '0;
      busy_reg <= '0;
    end else if (max) begin
      mask_reg <= '0;
      count <= '0;
      prev_res <= '0;
      prev_mask <= '0;
      busy_reg <= '0;
    end else begin
      mask_reg <= next_mask_reg;
      count <= next_count;
      prev_res <= next_prev_res;
      prev_mask <= next_prev_mask;
      busy_reg <= next_busy;
    end
  end

  always_comb begin
    iif.res0 = '0;
    iif.res1 = '0;
    next_mask_reg = mask_reg;
    next_count = count;
    next_prev_res = prev_res;
    next_prev_mask = prev_mask;
    next_busy = busy_reg;
    if (iif.start) begin
      next_busy = 1;
      if (iif.sew == SEW32) begin
        iif.res0 = out1;
        iif.res1 = out2;
        next_mask_reg = temp >> 2;
        next_count = count + 2;
        next_prev_res = out2;
        next_prev_mask = temp[1];
      end
      else if (iif.sew == SEW16) begin
        iif.res0 = {out2[15:0], out1[15:0]};
        iif.res1 = {out4[15:0], out3[15:0]};
        next_mask_reg = temp >> 4;
        next_count = count + 4;
        next_prev_res = out4;
        next_prev_mask = temp[3];
      end
      else if (iif.sew == SEW8) begin
        iif.res0 = {out4[7:0], out3[7:0], out2[7:0], out1[7:0]};
        iif.res1 = {out8[7:0], out7[7:0], out6[7:0], out5[7:0]};
        next_mask_reg = temp >> 8;
        next_count = count + 8;
        next_prev_res = out8;
        next_prev_mask = temp[7];
      end
    end
  end
endmodule
