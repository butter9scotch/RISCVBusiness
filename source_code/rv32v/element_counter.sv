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
  element_counter_if.decode ele_if
);
  // import rv32i_types_pkg::*;
  import rv32i_types_pkg::*;
  offset_t next_offset;
  // logic next_done;

  

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
      ele_if.offset <= 0;
      ele_if.done <= 0;
    end else if (ele_if.clear) begin
      ele_if.offset <= 0;
      ele_if.done <= 0;
    end else if (ele_if.ex_return & ele_if.de_en) begin
      ele_if.offset <= ele_if.vstart;
      ele_if.done <= ele_if.next_done;
    end else if (ele_if.offset + NUM_LANES >= ele_if.vl & ~ele_if.busy_ex) begin
      ele_if.offset <= 0;
      ele_if.done <= ele_if.next_done;
    end else if (ele_if.done) begin
      ele_if.offset <= 0;
      ele_if.done <= ele_if.next_done;
    end else if (ele_if.de_en  & ~ele_if.stall)begin
      ele_if.offset <= ele_if.offset + NUM_LANES; //in this case 2
      ele_if.done <= ele_if.next_done;
    end
  end

  always_comb begin
    next_offset = ele_if.offset;
    if (ele_if.ex_return & ele_if.de_en) begin
      // if (ele_if.slide1up) begin
      //   next_offset = ele_if.vstart + 1;
      // end else begin
      // end
        next_offset = ele_if.vstart;
    end else if (ele_if.offset + NUM_LANES >= ele_if.vl) begin
      next_offset = 0;
    end else if (ele_if.done) begin
      next_offset = 0;
    end else if ((ele_if.de_en == 1) & ~ele_if.stall)begin
      next_offset = ele_if.offset + NUM_LANES; //in this case 2
    end
  end

  always_comb begin
    ele_if.next_done = 0;
    if ((ele_if.offset + 3 >= ele_if.vl && (ele_if.vl > 0)) && ele_if.de_en) begin
      ele_if.next_done = 1; 
    end
  end


endmodule
