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
*   Filename:     element_counter.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 10/13/2021
*   Description:  Tracks current vector element for vector instructions
*                  
*/
`include "element_counter_if.vh"

module element_counter (
  input CLK, nRST,
  element_counter_if.ec ele_if
);
  import rv32i_types_pkg::*;
  import rv32v_types_pkg::*;

  offset_t next_offset;
  logic [4:0] next_uop_vl;

  

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
      ele_if.offset <= 0;
      ele_if.uop_vl <= 0;
    end else if (ele_if.clear) begin
      ele_if.offset <= 0;
      ele_if.uop_vl <= 0;
    end else begin
      ele_if.offset <= next_offset;
      ele_if.uop_vl <= next_uop_vl;
    end
  end

  always_comb begin
    next_offset = ele_if.offset;
    if (ele_if.ex_return & ele_if.de_en) begin
      next_offset = ele_if.vstart;
    end else if ((ele_if.de_en == 1) & ~ele_if.stall)begin
      next_offset = ele_if.offset + NUM_LANES; //in this case 2
    end
  end

  always_comb begin
    ele_if.done = 0;
    ele_if.shift_ena = 0;
    if (ele_if.offset >= ele_if.vl) begin
      ele_if.done = 1; 
    end else if (ele_if.sew == SEW32) begin
      ele_if.shift_ena = (ele_if.offset != 0) && ((ele_if.offset % 4) == 0);
    end else if (ele_if.sew == SEW16) begin
      ele_if.shift_ena = (ele_if.offset != 0) && ((ele_if.offset % 8) == 0);
    end else if (ele_if.sew == SEW8) begin
      ele_if.shift_ena = (ele_if.offset != 0) && ((ele_if.offset % 16) == 0);
    end
  end

  always_comb begin
    next_uop_vl = 1 << (4 - ele_if.sew);
    if (ele_if.sew == SEW8) begin
      if ((next_offset >> 4) + 1 > ele_if.vl >> 4) begin
        next_uop_vl = ele_if.vl % 16;
      end
      if (ele_if.uop_vl > 16) $error("uop_vl overflow, SEW8");
    end else if (ele_if.sew == SEW16) begin
      if ((next_offset >> 3) + 1 > ele_if.vl >> 3) begin
        next_uop_vl = ele_if.vl % 8;
      end
      if (ele_if.uop_vl > 8) $error("uop_vl overflow, SEW16");
    end else if (ele_if.sew == SEW32) begin
      if ((next_offset >> 2) + 1 > ele_if.vl >> 2) begin
        next_uop_vl = ele_if.vl % 4;
      end
      if (ele_if.uop_vl > 4) $error("uop_vl overflow, SEW32");
    end
  end


endmodule