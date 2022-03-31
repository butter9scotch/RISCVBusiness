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
//`include "element_counter_if.vh"

import rv32i_types_pkg::*;

module counter (
  input logic CLK, nRST,
  input [31:0] vstart, vl,
  input logic stall, ex_return, de_en, clear, busy_ex, 
  output offset_t offset,
  output logic done, next_done
);
  // import rv32i_types_pkg::*;
  logic done_reg;
  
  offset_t next_offset;
  //offset_t offset;
  //logic  done, next_done;
  //logic [31:0] vstart, vl;
  //logic stall, ex_return, de_en, clear, busy_ex;
  

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
      offset <= 0;
      done_reg <= 0;
    end else if (clear) begin
      offset <= 0;
      done_reg <= 0;
    end else if (ex_return & de_en) begin
      offset <= vstart;
      done_reg <= next_done;
    end else if (offset + NUM_LANES >= vl & ~busy_ex) begin
      offset <= 0;
      done_reg <= next_done;
    end else if (done_reg) begin
      offset <= 0;
      done_reg <= next_done;
    end else if (de_en  & ~stall)begin
      offset <= offset + NUM_LANES; //in this case 2
      done_reg <= next_done;
    end
  end

  always_comb begin
    next_offset = offset;
    if (ex_return & de_en) begin
        next_offset = vstart;
    end else if (offset + NUM_LANES >= vl) begin
      next_offset = 0;
    end else if (done_reg) begin
      next_offset = 0;
    end else if ((de_en == 1) & ~stall)begin
      next_offset = offset + NUM_LANES; //in this case 2
    end
  end

  always_comb begin
    next_done = 0;
    if ((offset + 3 >= vl && (vl > 0)) && de_en) begin
      next_done = 1; 
    end
  end

  always_comb begin
    if (vl == 1 || vl == 2) begin
      done = de_en;
    end else begin
      done = done_reg & de_en;
    end
  end

endmodule
