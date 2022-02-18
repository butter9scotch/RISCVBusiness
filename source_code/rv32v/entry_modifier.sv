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
*   Filename:     entry_modifier.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 2/5/2022
*   Description:  Modify entry before writing to ROB
*/

`include "entry_modifier_if.vh"

module entry_modifier (
  entry_modifier_if.em em_if
);
  import rv32i_types_pkg::*;

  always_comb begin
    case(em_if.sew)
      SEW32: begin
        em_if.vd_outer_offset    = em_if.woffset[1:0] << 5;
        em_if.vd_wen_offset      = em_if.woffset[1:0] << 2;
        em_if.final_index        = em_if.index + em_if.woffset[4:2];
        em_if.final_vd           = em_if.vd + em_if.woffset[4:2];
        em_if.filled_one_entry   = em_if.woffset[1:0] == 2'b11 || em_if.woffset[1:0] == 2'b10;
      end
      SEW16: begin 
        em_if.vd_outer_offset    = em_if.woffset[2:0] << 4;
        em_if.vd_wen_offset      = em_if.woffset[2:0] << 1;
        em_if.final_index        = em_if.index + em_if.woffset[5:3];
        em_if.final_vd           = em_if.vd + em_if.woffset[5:3];
        em_if.filled_one_entry   = em_if.woffset[2:0] == 3'b111 || em_if.woffset[2:0] == 3'b110;
      end
      default: begin
        em_if.vd_outer_offset    = em_if.woffset[3:0] << 3;
        em_if.vd_wen_offset      = em_if.woffset[3:0];
        em_if.final_index        = em_if.index + em_if.woffset[6:4];
        em_if.final_vd           = em_if.vd + em_if.woffset[6:4];
        em_if.filled_one_entry   = em_if.woffset[2:0] == 4'b1111 || em_if.woffset[2:0] == 4'b1110;
      end 
    endcase 
  end

endmodule
