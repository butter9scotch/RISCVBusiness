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
*   Filename:     encoder.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 11/13/2021
*   Description:  Modified priority encoder
*/

module encoder (
  input logic [31:0] in,
  input logic [31:0] ena,
  output logic strobe,
  output logic [4:0] out
);    
   assign {out,strobe} = in[0] & ena[0] ? {5'd0,1'b1} :
			 in[1] & ena[1] ? {5'd1,1'b1} :
			 in[2] & ena[2] ? {5'd2,1'b1} :
			 in[3] & ena[3] ? {5'd3,1'b1} :
			 in[4] & ena[4] ? {5'd4,1'b1} :
			 in[5] & ena[5] ? {5'd5,1'b1} :
			 in[6] & ena[6] ? {5'd6,1'b1} :
			 in[7] & ena[7] ? {5'd7,1'b1} :
			 in[8] & ena[8] ? {5'd8,1'b1} :
			 in[9] & ena[9] ? {5'd9,1'b1} :
			 in[10] & ena[10] ? {5'd10,1'b1} :
			 in[11] & ena[11] ? {5'd11,1'b1} :
			 in[12] & ena[12] ? {5'd12,1'b1} :
			 in[13] & ena[13] ? {5'd13,1'b1} :
			 in[14] & ena[14] ? {5'd14,1'b1} :
			 in[15] & ena[15] ? {5'd15,1'b1} :
			 in[16] & ena[16] ? {5'd16,1'b1} :
			 in[17] & ena[17] ? {5'd17,1'b1} :
			 in[18] & ena[18] ? {5'd18,1'b1} :
			 in[19] & ena[19] ? {5'd19,1'b1} :
			 in[20] & ena[20] ? {5'd20,1'b1} :
			 in[21] & ena[21] ? {5'd21,1'b1} :
			 in[22] & ena[22] ? {5'd22,1'b1} :
			 in[23] & ena[23] ? {5'd23,1'b1} :
			 in[24] & ena[24] ? {5'd24,1'b1} :
			 in[25] & ena[25] ? {5'd25,1'b1} :
			 in[26] & ena[26] ? {5'd26,1'b1} :
			 in[27] & ena[27] ? {5'd27,1'b1} :
			 in[28] & ena[28] ? {5'd28,1'b1} :
			 in[29] & ena[29] ? {5'd29,1'b1} :
			 in[30] & ena[30] ? {5'd30,1'b1} :
			 in[31] & ena[31] ? {5'd31,1'b1} :
                         7'b0000000;		 
      
endmodule
