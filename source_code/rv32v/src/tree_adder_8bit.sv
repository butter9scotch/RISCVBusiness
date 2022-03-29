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
*   Filename:     tree_adder_8bit.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 11/13/2021
*   Description:  Adder to find number of set bits in 8 bit data
*/

module tree_adder_8bit (
  input logic [7:0] add_in,
  output logic [3:0] add_out
);    

  logic c0, c1, c2, c3, c4, c5, c6;
  logic s0, s1, s2, s3, s4, s5, s6;
  
  // Layer 0
  mul_fa FA0 (.x(add_in[0]), .y(add_in[1]), .cin(add_in[2]), .cout(c0), .sum(s0));
  mul_fa FA1 (.x(add_in[3]), .y(add_in[4]), .cin(add_in[5]), .cout(c1), .sum(s1));
  mul_fa FA2 (.x(add_in[6]), .y(add_in[7]), .cin(0), .cout(c2), .sum(s2));

  // Layer 1 
  mul_fa FA3 (.x(s0), .y(s1), .cin(s2), .cout(c3), .sum(s3));
  mul_fa FA4 (.x(c0), .y(c1), .cin(c2), .cout(c4), .sum(s4));

  // Layer 2
  mul_fa FA5 (.x(c3), .y(s4), .cin(0), .cout(c5), .sum(s5));
  mul_fa FA6 (.x(c4), .y(c5), .cin(0), .cout(c6), .sum(s6));

  assign add_out = {c6, s6, s5, s3};
      
endmodule
