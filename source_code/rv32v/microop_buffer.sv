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
*   Filename:     microop_buffer.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 10/15/2021
*   Description:  Break vector instr into microops if LMUL > 1
*/

module microop_buffer (
  input logic CLK, 
  input logic nRST,
  input logic [3:0] LMUL,
  input logic shift_ena,
  input logic start,
  input logic clear,
  input logic [31:0] instr,
  output logic [31:0] microop
);

  logic [4:0] rsel1, rsel2;
  logic [4:0] rsel1_p1, rsel1_p2, rsel1_p3, rsel1_p4, rsel1_p5, rsel1_p6, rsel1_p7;
  logic [4:0] rsel2_p1, rsel2_p2, rsel2_p3, rsel2_p4, rsel2_p5, rsel2_p6, rsel2_p7;
  logic [4:0] sel1_p1, sel1_p2, sel1_p3, sel1_p4, sel1_p5, sel1_p6, sel1_p7;
  logic [4:0] sel2_p1, sel2_p2, sel2_p3, sel2_p4, sel2_p5, sel2_p6, sel2_p7;
  logic [31:0] instr_p1, instr_p2, instr_p3, instr_p4, instr_p5, instr_p6, instr_p7;
  logic [223:0] buffer, next_buffer;
  logic a_type, a_type_vs1, ls_index, ls_type;

  assign rsel1 = instr[19:15];
  assign rsel2 = instr[24:20];
  assign a_type = instr[6:0] == 7'b1010111;
  assign a_type_vs1 = (instr[14:12] == 0) || (instr[14:12] == 1) || (instr[14:12] == 2);
  assign ls_index = (instr[27:26] == 2'b01) || (instr[27:26] == 2'b11);
  assign ls_type = (instr[6:0] == 7'b0000111) || (instr[6:0] == 7'b0100111);

  assign rsel1_p1 = rsel1 + 1;
  assign rsel1_p2 = rsel1 + 2;
  assign rsel1_p3 = rsel1 + 3;
  assign rsel1_p4 = rsel1 + 4;
  assign rsel1_p5 = rsel1 + 5;
  assign rsel1_p6 = rsel1 + 6;
  assign rsel1_p7 = rsel1 + 7;

  assign sel1_p1 = a_type & a_type_vs1 ? rsel1_p1 : instr[19:15];
  assign sel1_p2 = a_type & a_type_vs1 ? rsel1_p2 : instr[19:15];
  assign sel1_p3 = a_type & a_type_vs1 ? rsel1_p3 : instr[19:15];
  assign sel1_p4 = a_type & a_type_vs1 ? rsel1_p4 : instr[19:15];
  assign sel1_p5 = a_type & a_type_vs1 ? rsel1_p5 : instr[19:15];
  assign sel1_p6 = a_type & a_type_vs1 ? rsel1_p6 : instr[19:15];
  assign sel1_p7 = a_type & a_type_vs1 ? rsel1_p7 : instr[19:15];

  assign rsel2_p1 = rsel2 + 1;
  assign rsel2_p2 = rsel2 + 2;
  assign rsel2_p3 = rsel2 + 3;
  assign rsel2_p4 = rsel2 + 4;
  assign rsel2_p5 = rsel2 + 5;
  assign rsel2_p6 = rsel2 + 6;
  assign rsel2_p7 = rsel2 + 7;

  assign sel2_p1 = (a_type | (ls_type & ls_index)) ? rsel2_p1 : instr[24:20];
  assign sel2_p2 = (a_type | (ls_type & ls_index)) ? rsel2_p2 : instr[24:20];
  assign sel2_p3 = (a_type | (ls_type & ls_index)) ? rsel2_p3 : instr[24:20];
  assign sel2_p4 = (a_type | (ls_type & ls_index)) ? rsel2_p4 : instr[24:20];
  assign sel2_p5 = (a_type | (ls_type & ls_index)) ? rsel2_p5 : instr[24:20];
  assign sel2_p6 = (a_type | (ls_type & ls_index)) ? rsel2_p6 : instr[24:20];
  assign sel2_p7 = (a_type | (ls_type & ls_index)) ? rsel2_p7 : instr[24:20];

  assign instr_p1 = {instr[31:25], sel2_p1, sel1_p1, instr[14:0]};
  assign instr_p2 = {instr[31:25], sel2_p2, sel1_p2, instr[14:0]};
  assign instr_p3 = {instr[31:25], sel2_p3, sel1_p3, instr[14:0]};
  assign instr_p4 = {instr[31:25], sel2_p4, sel1_p4, instr[14:0]};
  assign instr_p5 = {instr[31:25], sel2_p5, sel1_p5, instr[14:0]};
  assign instr_p6 = {instr[31:25], sel2_p6, sel1_p6, instr[14:0]};
  assign instr_p7 = {instr[31:25], sel2_p7, sel1_p7, instr[14:0]};

  assign next_buffer = LMUL == 2 ? {192'd0, instr_p1} :
                       LMUL == 3 ? {160'd0, instr_p2, instr_p1} :
                       LMUL == 4 ? {128'd0, instr_p3, instr_p2, instr_p1} :
                       LMUL == 5 ? {96'd0, instr_p4, instr_p3, instr_p2, instr_p1} :
                       LMUL == 6 ? {64'd0, instr_p5, instr_p4, instr_p3, instr_p2, instr_p1} :
                       LMUL == 7 ? {32'd0, instr_p6, instr_p5, instr_p4, instr_p3, instr_p2, instr_p1} :
                       LMUL == 8 ? {instr_p7, instr_p6, instr_p5, instr_p4, instr_p3, instr_p2, instr_p1} :
                       '0;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      buffer <= '0;
    end else if (clear) begin
      buffer <= '0;
    end else if (shift_ena) begin
      buffer <= (buffer >> 32);
    end else if (start) begin
      buffer <= next_buffer;
    end
  end

  assign microop = buffer[31:0]; 
  
endmodule
