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

  import rv32i_types_pkg::*;

  offset_t woffset0, woffset1, next_woffset0, next_woffset1, prev_woffset, cout;

  assign cou_if.woffset0 = next_woffset0;
  assign cou_if.woffset1 = next_woffset1;
  assign cou_if.wen = cou_if.vs1_mask;
  assign cou_if.busy = cou_if.ena;
  //assign mask_bit_checking = done_mask1 ? ~mask2bit : mask2bit;
  //assign cou_if.checking_mask0_1 = ~done_mask1;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      woffset0 <= '0;
      woffset1 <= '0;
      prev_woffset <= '0;
      //cou_if.busy <= '0;
    end else if (cou_if.done | cou_if.reset) begin // When element counter reaches VL
      woffset0 <= '0;
      woffset1 <= '0;
      prev_woffset <= '0;
      //cou_if.busy <= '0; 
    end else if (cou_if.ena) begin
      woffset0 <= next_woffset0;
      woffset1 <= next_woffset1;
      prev_woffset <= cou_if.woffset1 + cout;
      //cou_if.busy <= 1;
    end
  end

  always_comb begin
    next_woffset0 = '0;
    next_woffset1 = '0;
    case(cou_if.vs1_mask)
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

endmodule
