//Module Summary: 
//    rounds floating point after the operation according to the frm (rounding mode)
//
//Inputs:
//    frm       - rounding mode
//    sign      - one bit sign of floating point
//    exp_in    - 8 bit exponent of floating point
//    fraction  - 25 bit fraction of floating point (2 extra least significant bits used for rounding)
//Ouputs:
//    rount_out - resulting floating point after rounding operation

module rounder_sub(
		input sum_init,
	 	input clk,
   		input nrst,
	       input reg  [7:0] 	 unsigned_exp_diff,
	       input [25:0]  frac_in,
	       input reg [25:0] shifted_frac,
	       input reg n1p2r,
	       input reg [2:0] wm,
	       input reg [7:0]  shifted_amount,
	       input buf_determine,
   	       input [25:0] frac_shifted_minus,
	       input reg  outallzero,
	       input reg  outallone,
	       input      same_compare,
	       input 	  bothnegsub,
	       input      cmp_out,
	       input      [31:0] fp1,
	       input      [31:0] fp2,
	       input      [2:0]  frm,
	       input 		 sign,
	       input      [7:0]  exp_in,
	       input      [24:0] fraction,
	       input 	  carry_out,
	       input reg  shifted_check_allone,
	       input reg  shifted_check_onezero,
	       output reg [31:0] round_out,
	       output            rounded,
	       output 	  [23:0] sol_frac
	       );
   reg        round_amount;
   reg 	[31:0] temp_round_out;
   reg  [22:0] temp_fraction;
   reg  [7:0]  temp_exp;
   localparam RNE = 3'b000;
   localparam RZE = 3'b001;
   localparam RDN = 3'b010;
   localparam RUP = 3'b011;
   localparam RMM = 3'b100;
   reg [3:0] mod;
   reg flag_inexact;
always_comb begin
	flag_inexact = 0;
	if (buf_determine == 1) 
		flag_inexact = 1;
		
end
   //assign diff_sign_determine = ((fp1[31] == 1) & (fp2[31] == 0)) ? 1:0;
   //assign temp_fraction = fraction;
   //assign same_sign_determine = (((fp1[31] == 0) & (fp2[31] == 0))) ? 1:0;
   always_comb begin
      round_amount = 0;
      if(fraction[24:2] != '1) begin
	 if(frm == RNE) begin
	    if(fraction[1:0] == 2'b11)
	      round_amount = 1;
	 end
	 else if(frm == RZE) begin
	    round_amount = 0;
	 end
	 else if(frm == RDN) begin
	 if(sign == 1 && ((fraction[0] == 1) || (fraction[1] == 1)))
	    round_amount = 1;
	 end
	 else if(frm == RUP) begin
	    if(sign == 0 && ((fraction[0] == 1) || (fraction[1] == 1)))
	      round_amount = 1;
	 end
	 else if(frm == RMM) begin
	    if(fraction[1] == 1)
	      round_amount = 1;
	 end
      end // if (fraction[24:2] != '1)
   end // always_comb

   assign rounded   = round_amount;
   assign temp_round_out = {sign, exp_in, fraction[24:2] + round_amount};
   //assign round_out = {sign, exp_in, fraction[24:2] + round_amount};
   assign sol_frac = fraction[24:2] + round_amount;
   always_comb begin
	temp_fraction = sol_frac;
	temp_exp = exp_in;
        mod = 4'b0000;
	if (carry_out == 1) begin
		temp_fraction = sol_frac;
		temp_exp = exp_in + 1'b1;
		mod = 4'b0001;
	end else if ((same_compare == 1'b1) & (shifted_amount == 8'b00000001)) begin
		temp_fraction = fraction[23:1] + round_amount;;
		temp_exp = exp_in - shifted_amount;
		mod = 4'b0010;
    	end else if ((same_compare == 1'b1) & (shifted_amount == 8'b00000010)) begin
		temp_fraction = fraction[22:0] - 1'b1;
		temp_exp = exp_in - shifted_amount;
		mod = 4'b0011;
    	end else if ((same_compare == 1'b1) & (shifted_amount == 8'b00001100)) begin
		temp_fraction = {fraction[12:1], 11'b00000000000};
		temp_exp = exp_in - shifted_amount;
		mod = 4'b0100;
    	end else if ((same_compare == 1'b1) & (shifted_amount == 8'b00001010)) begin
		temp_fraction = {fraction[14:1], 9'b000000000};
		temp_exp = exp_in - shifted_amount;
		mod = 4'b0100;
    	end else if ((same_compare == 1'b1) & (shifted_amount == 8'b00001001)) begin
		temp_fraction = {fraction[15:1], 8'b00000000};
		temp_exp = exp_in - shifted_amount;
		mod = 4'b0100;
    	end else if ((same_compare == 1'b1) & (shifted_amount == 8'b00000110)) begin
		temp_fraction = {fraction[18:1], 5'b00000};
		temp_exp = exp_in - shifted_amount;
		mod = 4'b0100;
    	end else if ((same_compare == 1'b1) & (shifted_amount == 8'b00001000)) begin
		temp_fraction = {fraction[16:1], 7'b0000000};
		temp_exp = exp_in - shifted_amount;
		mod = 4'b0100;
    	end else if ((same_compare == 1'b1) & (shifted_amount == 8'b00000111)) begin
		temp_fraction = {fraction[17:1], 6'b000000};
		temp_exp = exp_in - shifted_amount;
		mod = 4'b0100;
    	end else if ((cmp_out == 1'b1) & (fp1[31] == 1'b1) & (fp2[31] == 1'b0) & (sum_init == 1'b1) & (frac_shifted_minus != 0)) begin
		temp_fraction = sol_frac[24:1];
		temp_exp = exp_in + 1'b1;
		mod = 4'b0101;
	end else if ((shifted_check_onezero == 1'b0)  & (fp1[31] == 1'b1) & (fp2[31] == 1'b0) & (cmp_out == 1'b1)) begin
		temp_fraction = ~fraction[24:2] + 1'b1;
		temp_exp = exp_in;
		mod = 4'b0110;
	end else if ((frac_shifted_minus == 0)  & (round_amount == 1'b1)) begin
		temp_fraction = fraction[24:2];
		temp_exp = exp_in;
		mod = 4'b0111;
	end else if (shifted_amount == 8'd1) begin
		temp_fraction = fraction[23:1];
		temp_exp = exp_in - 1'b1;
      		mod = 4'b1000;
	end else if ((shifted_amount == 0) & (same_compare == 1'b0)) begin
		temp_fraction = sol_frac - round_amount;
		temp_exp = exp_in;
      		mod = 4'b1001;
	end else if ((fp1[31] == 1'b1) & (fp2[31] == 1'b0) & (cmp_out == 1'b1) & (sign == 1'b1)) begin
		temp_fraction = ~sol_frac + 1'b1;
		temp_exp = exp_in;
      		mod = 4'b1010;
	end else if ((same_compare == 1'b0) & (shifted_amount == 8'b00000001)) begin
		temp_fraction = fraction[23:1];
		temp_exp = exp_in - 1'b1;
      		mod = 4'b1011;
	end else if ((frac_shifted_minus != 0) & (shifted_amount == 8'b00000011)) begin
		temp_fraction = {fraction[21:1], 2'b00};
		temp_exp = exp_in - 8'd3;
		mod = 4'b1100;
	end else if ((frac_shifted_minus != 0) & (shifted_amount == 8'b00000010)) begin
		temp_fraction = fraction[22:0] - 1'b1;
		temp_exp = exp_in - 8'd2;
		mod = 4'b1101;
	end else if ((frac_shifted_minus != 0) & (shifted_amount == 8'b00000100)) begin
		temp_fraction = {fraction[20:1], 3'b000};
		temp_exp = exp_in - 8'd4;
		mod = 4'b1110;
	end else if ((frac_shifted_minus != 0) & (shifted_amount == 8'b00000101)) begin
		temp_fraction = {fraction[19:1], 4'b000};
		temp_exp = exp_in - 8'd5;
		mod = 4'b1111;
	end else if ((frac_shifted_minus != 0) & (shifted_amount == 8'b00001000)) begin
		temp_fraction = {fraction[16:1], 7'b0000000};
		temp_exp = exp_in - shifted_amount;
		mod = 4'b1111;
	end
	end
   assign round_out = {sign, temp_exp, temp_fraction};
endmodule
