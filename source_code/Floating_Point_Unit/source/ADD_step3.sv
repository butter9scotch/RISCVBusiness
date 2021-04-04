
module ADD_step3
  (
   input logic out_of_range,
   input    reg        mul_ovf,
   input reg         mul_carry_out,
   input [6:0] 	 function_mode,
   input [31:0]  floating_point1,
   input [31:0]  floating_point2,
   input 	 ovf_in,
   input 	 unf_in,
   input 	 dz, // divide by zero flag
   input 	 inv,
   input [2:0] 	 frm,
   input [7:0] 	 exponent_max_in,
   input 	 sign_in,
   input [25:0]  frac_in,
   input 	 carry_out,
   output [31:0] add_floating_point_out,
   output reg ovf,
   output reg unf,
   output reg inexact
   );
   localparam quietNaN = 32'b01111111110000000000000000000000;
   localparam signalNaN = 32'b01111111101000000000000000000000;
   localparam Inf = 32'b01111111100000000000000000000000;
   localparam NegInf = 32'b11111111100000000000000000000000;
   localparam zero = 32'b00000000000000000000000000000000;
   localparam NegZero = 32'b10000000000000000000000000000000;
   //reg        inexact;
   wire        sign;
   wire [7:0]  exponent;
   wire [22:0] frac;
   
   assign {sign, exponent, frac} = add_floating_point_out;
   reg [31:0] dummy_floating_point_out;
   reg [7:0] exp_minus_shift_amount;
   reg [25:0] shifted_frac;
   reg [7:0]  shifted_amount;
   reg [7:0]  exp_out;
   //reg        ovf;
   //reg        unf;
   

   left_shift shift_left (
			  .fraction(frac_in),
			  .result(shifted_frac),
			  .shifted_amount(shifted_amount)
			  );
   
   subtract SUB (
		 .exp1(exponent_max_in),
		 .shifted_amount(shifted_amount),
		 .result(exp_minus_shift_amount)
		 );

   
   reg [24:0] round_this;
   
   always_comb begin
      ovf = 0;
      unf = 0;
      if(carry_out == 1) begin
	 round_this = frac_in[25:1] + 1'b1;
	 exp_out    = exponent_max_in + 1;
	 if((exponent_max_in == 8'b11111110) && (~unf_in)) ovf = 1;
      end
      else begin
	 round_this = shifted_frac[24:0];
	 exp_out    = exp_minus_shift_amount;
	 if(({1'b0, exponent_max_in} < shifted_amount) && (~ovf_in)) unf = 1;
      end
   end
reg [31:0] fp_option;
   reg [31:0] round_out;
   
   rounder ROUND (
		  .frm(frm),
		  .sign(sign_in),
		  .exp_in(exp_out),
		  .fraction(round_this),
		  .round_out(round_out),
		  .rounded(round_flag)
		  );
   
   assign inexact                  = ovf_in | ovf | unf_in | unf | round_flag;
   //assign flags                    = {inv, dz, (ovf | ovf_in), (unf | unf_in), inexact};
   assign dummy_floating_point_out[31]   = round_out[31];
   assign dummy_floating_point_out[30:0] = inv    ? 31'b1111111101111111111111111111111 :
				     ovf_in ? 31'b1111111100000000000000000000000 :
				     ovf    ? 31'b1111111100000000000000000000000 :
				     unf_in ? 31'b0000000000000000000000000000000 :
				     unf    ? 31'b0000000000000000000000000000000 :
				     round_out[30:0];
 always_comb begin
	fp_option = dummy_floating_point_out;
	if (function_mode == 7'b0001000) begin
	 	/*if ((exponent_max_in == 8'b11111111) & (mul_carry_out == 1'b1)) begin
		fp_option = {round_out[31],31'b1111111100000000000000000000000};
		end*/ //(exponent_max_in == 8'b11111111)
		if ((out_of_range == 1'b1)) begin
		fp_option = {round_out[31],31'b1111111100000000000000000000000};
		end
	end
  end

assign add_floating_point_out = fp_option;
endmodule
