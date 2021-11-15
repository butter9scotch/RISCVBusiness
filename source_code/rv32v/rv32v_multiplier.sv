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
*   Filename:     rv32v_multiplier.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 11/7/2021
*   Description:  Pipelined wallace tree multiplier that supports overlapping of MUL instr
*/

module rv32v_multiplier
(
	input logic CLK,
	input logic nRST,
	input logic [31:0] multiplicand,
	input logic [31:0] multiplier,
	input logic [1:0] is_signed,
	input logic start,
	output logic finished,
	output logic [63:0] product
);
	//logic start_reg;
	logic [31:0] multiplicand_reg;
	logic [31:0] multiplier_reg, multiplier_reg1, multiplier_reg2;
	logic [63:0] result;
	logic [63:0] result2;
	logic [63:0] temp_product;
	logic [63:0] temp_product2;
	logic [31:0] multiplicand_mod, multiplicand_mod1, multiplicand_mod2;
	logic [31:0] multiplier_mod;
	logic adjust_product, adjust_product1, adjust_product2;
	logic [63:0] partial_product [15:0];
	logic [63:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7, pp8, pp9, pp10, pp11, pp12, pp13, pp14, pp15, pp15_pip;
	logic [32:0] mul_plus2, mul_minus2, mul_minus1;
	logic [63:0] pp [15:0];
	logic [32:0] modified_in;
	logic [63:0] sum0, sum1, sum2, sum3, sum4, sum5, sum6, sum7, sum8, sum9, sum10, sum11, sum12, sum13, sum4_pip; 	
	logic [63:0] cout0, cout1, cout2, cout3, cout4, cout5, cout6, cout7, cout8, cout9, cout10, cout11, cout12, cout13;
	logic [1:0] count;
	logic ff1, ff2; 
	//logic [63:0] sum13_pip, cout13_pip;
	logic [63:0] sum5_pip, cout5_pip, sum6_pip, cout6_pip, sum7_pip, cout7_pip;
	logic [1:0] is_signed_reg, is_signed_reg1, is_signed_reg2;
	logic done;
	logic count_ena;	
	integer i, j;

	always_ff @ (posedge CLK, negedge nRST) begin
		if (nRST == 0) begin
			multiplicand_reg <= '0;
			multiplier_reg <= '0;
			is_signed_reg <= '0;
		end
		else if (start) begin
			multiplicand_reg <= multiplicand;
			multiplier_reg <= multiplier;
			is_signed_reg <= is_signed;
		end
	end
	// Modify multiplicand and multiplier if they are signed
	assign multiplicand_mod = is_signed_reg[1] && multiplicand_reg[31] ? (~(multiplicand_reg)+1) : multiplicand_reg;
	assign multiplier_mod = is_signed_reg[0] && multiplier_reg[31] ? (~(multiplier_reg)+1) : multiplier_reg;
	// Control signal to modify final product
 	assign adjust_product   = (is_signed_reg[0] & multiplier_reg[31]) ^ (is_signed_reg[1] & multiplicand_reg[31]);
	// For bit pair recoding part
	assign mul_plus2 = multiplicand_mod + multiplicand_mod;
	assign mul_minus2 = ~mul_plus2 + 1;
	assign mul_minus1 = ~multiplicand_mod + 1;
	assign modified_in = {multiplier_mod,1'b0};

	// STAGE 1: BOOTH ENCODER
	// Bit pair recoding to generate partial product
	always_comb begin
		for (i = 0; i < 32; i = i + 2) begin
			case ({modified_in[i+2], modified_in[i+1], modified_in[i]})
				3'b000:
					pp[i/2] = '0; //0
				3'b001:
					pp[i/2] = {{32'd0},multiplicand_mod}; // +1M
				3'b010:
					pp[i/2] = {{32'd0},multiplicand_mod}; // +1M
				3'b011:
					pp[i/2] = {{31'd0},mul_plus2}; // +2M
				3'b100:
					if (mul_minus2 == 0) pp[i/2] = '0;
					else pp[i/2] = {{31{1'b1}},mul_minus2}; // -2M
				3'b101:
					if (mul_minus1 == 0) pp[i/2] = '0;
					else pp[i/2] = {{31{1'b1}},mul_minus1}; // -1M
				3'b110:
					if (mul_minus1 == 0) pp[i/2] = '0;
					else pp[i/2] = {{31{1'b1}},mul_minus1}; // -1M
				3'b111:
					pp[i/2] = '0;
			endcase
		end
	end
	// Shift partial product
	always_comb begin
		for (j = 0; j < 16; j = j + 1) 
			begin
				partial_product[j] = pp[j] << (2*j); // Shift with multiple of 2 (Radix 4)
			end
	end

	// Pipeline register before wallace tree
	always_ff @ (posedge CLK, negedge nRST) begin
		if (nRST == 0) begin
			pp0 <= '0;
			pp1 <= '0;
			pp2 <= '0;
			pp3 <= '0;
			pp4 <= '0;
			pp5 <= '0;
			pp6 <= '0;
			pp7 <= '0;
			pp8 <= '0;
			pp9 <= '0;
			pp10 <= '0;
			pp11 <= '0;
			pp12 <= '0;
			pp13 <= '0;
			pp14 <= '0;
			pp15 <= '0;
                        is_signed_reg1 <= '0;
                        multiplier_reg1 <= '0;
                        multiplicand_mod1 <= '0;
                        adjust_product1 <= '0;
		end
		else begin
			pp0 <= partial_product[0];
			pp1 <= partial_product[1];
			pp2 <= partial_product[2];
			pp3 <= partial_product[3];
			pp4 <= partial_product[4];
			pp5 <= partial_product[5];
			pp6 <= partial_product[6];
			pp7 <= partial_product[7];
			pp8 <= partial_product[8];
			pp9 <= partial_product[9];
			pp10 <= partial_product[10];
			pp11 <= partial_product[11];
			pp12 <= partial_product[12];
			pp13 <= partial_product[13];
			pp14 <= partial_product[14];
			pp15 <= partial_product[15];
                        is_signed_reg1 <= is_signed_reg;
                        multiplier_reg1 <= multiplier_reg;
                        multiplicand_mod1 <= multiplicand_mod;
                        adjust_product1 <= adjust_product;
		end
	end
	
	// STAGE 2: WALLACE TREE 
	// Layer 1
	mul_csa #(64) CSA0 (.x(pp0), .y(pp1), .z(pp2), .cout(cout0), .sum(sum0));
	mul_csa #(64) CSA1 (.x(pp3), .y(pp4), .z(pp5), .cout(cout1), .sum(sum1));
	mul_csa #(64) CSA2 (.x(pp6), .y(pp7), .z(pp8), .cout(cout2), .sum(sum2));
	mul_csa #(64) CSA3 (.x(pp9), .y(pp10), .z(pp11), .cout(cout3), .sum(sum3));
	mul_csa #(64) CSA4 (.x(pp12), .y(pp13), .z(pp14), .cout(cout4), .sum(sum4)); // remaining partialproduct 15
	// Layer 2
	mul_csa #(64) CSA5 (.x(cout0), .y(sum0), .z(cout1), .cout(cout5), .sum(sum5));
	mul_csa #(64) CSA6 (.x(sum1), .y(cout2), .z(sum2), .cout(cout6), .sum(sum6));
	mul_csa #(64) CSA7 (.x(cout3), .y(sum3), .z(cout4), .cout(cout7), .sum(sum7)); // remaining sum4
	// Pipeline register in wallace tree between layer 2 and layer 3	
	always_ff @ (posedge CLK, negedge nRST) begin
		if (nRST == 0) begin
			cout5_pip <= '0;
			sum5_pip <= '0;
			cout6_pip <= '0;
			sum6_pip <= '0;
			cout7_pip <= '0;
			sum7_pip <= '0;
                        pp15_pip <= '0;
                        sum4_pip <= '0;
                        is_signed_reg2 <= '0;
                        multiplier_reg2 <= '0;
                        multiplicand_mod2 <= '0;
                        adjust_product2 <= '0;
		end
		else begin
			cout5_pip <= cout5;
			sum5_pip <= sum5;
			cout6_pip <= cout6;
			sum6_pip <= sum6;
			cout7_pip <= cout7;
			sum7_pip <= sum7;
                        pp15_pip <= pp15;
                        sum4_pip <= sum4;
                        is_signed_reg2 <= is_signed_reg1;
                        multiplier_reg2 <= multiplier_reg1;
                        multiplicand_mod2 <= multiplicand_mod1;
                        adjust_product2 <= adjust_product1;
		end
	end

	// Layer 3
	mul_csa #(64) CSA8 (.x(cout5_pip), .y(sum5_pip), .z(cout6_pip), .cout(cout8), .sum(sum8));
	mul_csa #(64) CSA9 (.x(sum6_pip), .y(cout7_pip), .z(sum7_pip), .cout(cout9), .sum(sum9));
	// Layer 4
	mul_csa #(64) CSA10 (.x(cout8), .y(sum8), .z(cout9), .cout(cout10), .sum(sum10));
	mul_csa #(64) CSA11 (.x(sum9), .y(pp15_pip), .z(sum4_pip), .cout(cout11), .sum(sum11)); 
	// Layer 5
	mul_csa #(64) CSA12 (.x(cout10), .y(sum10), .z(cout11), .cout(cout12), .sum(sum12));	// remaining sum11
	// Layer 6
	mul_csa #(64) CSA13 (.x(cout12), .y(sum12), .z(sum11), .cout(cout13), .sum(sum13));

	// STAGE 3: NORMAL ADDER	
	assign temp_product = cout13 + sum13;
	assign temp_product2 = is_signed_reg2[0] == 0 && multiplier_reg2[31] ? temp_product + ({{33{multiplicand_mod2[31]}},multiplicand_mod2} << 32) : temp_product; // plus extra 1M
	assign product = adjust_product2 ? (~temp_product2)+1: temp_product2;

        // Finished logic (delay start by 3 cycles)
	always_ff @ (posedge CLK, negedge nRST) begin
		if (nRST == 0) begin
                        ff1 <= '0;
                        ff2 <= '0;
			finished <= '0;
		end
		else begin
                        ff1 <= start;
                        ff2 <= ff1;
			finished <= ff2;
		end
	end
	
endmodule
