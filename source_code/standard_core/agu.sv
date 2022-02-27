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
*   Filename:     agu.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: /21/2016
*   Description:  Address Generation Unit
*/

module agu (
  input logic [31:0] port_a,
  input logic [31:0] port_b,
  input load_t load_type,
  output logic [3:0] byte_en_standard,
  output logic [31:0] address,
  output logic mal_addr  
);
  
  import rv32i_types_pkg::*;

  logic [1:0] byte_offset;

  // Generate address
  assign address = port_a + port_b;

  // misaligned address
  always_comb begin
    unique case(address)
      LB : begin
        unique case(byte_offset)
          2'b00   : byte_en_standard = 4'b0001;
          2'b01   : byte_en_standard = 4'b0010;
          2'b10   : byte_en_standard = 4'b0100;
          2'b11   : byte_en_standard = 4'b1000;
          default : byte_en_standard = 4'b0000;
        endcase
      end
      LBU : begin
        unique case(byte_offset)
          2'b00   : byte_en_standard = 4'b0001;
          2'b01   : byte_en_standard = 4'b0010;
          2'b10   : byte_en_standard = 4'b0100;
          2'b11   : byte_en_standard = 4'b1000;
          default : byte_en_standard = 4'b0000;
        endcase
      end
      LH : begin
        unique case(byte_offset)
          2'b00   : byte_en_standard = 4'b0011;
          2'b10   : byte_en_standard = 4'b1100;
          default : byte_en_standard = 4'b0000;
        endcase
      end
      LHU : begin
        unique case(byte_offset)
          2'b00   : byte_en_standard = 4'b0011;
          2'b10   : byte_en_standard = 4'b1100;
          default : byte_en_standard = 4'b0000;
        endcase
      end
      LW:           byte_en_standard = 4'b1111;
      default :     byte_en_standard = 4'b0000;
    endcase
  end
    logic [3:0] byte_en;
  // misaligned address
  always_comb begin
    if(byte_en == 4'hf) 
      mal_addr = (execute_mem_if.memory_addr[1:0] != 2'b00);
    else if (byte_en == 4'h3 || byte_en == 4'hc) begin
      mal_addr = (execute_mem_if.memory_addr[1:0] == 2'b01 || execute_mem_if.memory_addr[1:0] == 2'b11);
    end
    else 
      mal_addr = 1'b0;
  end
  

endmodule
