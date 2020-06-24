//By            : Joe Nasti
//Last Updated  : 7/23/18
//
//Module Summary: 
//    Third step of addition operation in three-step pipeline.
//    Rounds result based on rounding mode (frm) and left shifts fraction if needed
//
//Inputs:
//    frm              - 3 bit rounding mode
//    exponent_max_in  - exponent of result floating point
//    sign_in          - sign of result floating point
//    frac_in          - fraction of result floating point
//    carry_out        - carry out from step 2
//Outputs:
//    floating_point_out - final floating point

module SUB_step3
  (
   input reg sum_init,
   input reg  [7:0] 	 unsigned_exp_diff,
   input reg n1p2r,
   input reg [2:0] wm,
   input clk,
   input nrst,
   input 	   [25:0] frac_shifted_minus,
   input reg outallzero,
   input reg outallone,
   input reg same_compare,
   //input 	 signout,
   input 	 bothnegsub,
   input 	 cmp_out,
   input [31:0]  floating_point1,
   input [31:0]  floating_point2,
   input [6:0] 	 function_mode,
   input 	 ovf_in,
   input 	 unf_in,
   input 	 dz, // divide by zero flag
   input 	 inv,
   input [2:0] 	 frm,
   input [7:0] 	 exponent_max_in, //exponent 
   input 	 sign_in,
   input [25:0]  frac_in,
   input 	 carry_out,
   input reg     shifted_check_allone,
   input reg     shifted_check_onezero,
   output [31:0] before_floating_point_out,
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

   localparam ADD = 7'b0100000;
   localparam MUL = 7'b0000010;
   localparam SUB = 7'b0100100; //add sub mode
   
   //assign {sign, exponent, frac} = before_floating_point_out;
   
   //reg [7:0] exp_minus_shift_amount;
   reg [25:0] shifted_frac;
   reg [7:0]  shifted_amount;
   reg [7:0]  exp_out;
   //reg        ovf;
   //reg        unf;
   reg 	      temp_sign;
   reg [31:0] dummy_floating_point_out;
   reg [31:0] fp_option;
   reg [31:0] hold_value;
   reg [23:0] rounded_frac;
// Left shifts an unsigned 26 bit value until the first '1' is the most significant bit and returns the amount shifted
   left_shift shift_left (
			  .fraction(frac_in),
			  .result(shifted_frac),
			  .shifted_amount(shifted_amount)
			  );

   assign 	 exp_out    = exponent_max_in;

   
   reg [24:0] round_this;
   reg [2:0] log_de;
//this comb logic is for rounding mode
   always_comb begin
      ovf = 0;
      unf = 0;
      log_de = 0;
      //if ((carry_out == 0) & (((floating_point1[31] == 0)&(floating_point2[31] == 0) & (cmp_out == 1)))) begin
      if (carry_out == 0) begin
	 log_de = 2'b01;
	 round_this = frac_in[24:0] + 1'b1;
	 if(({1'b0, exponent_max_in} < shifted_amount) && (~ovf_in)) unf = 1;
      end else begin
	 round_this = frac_in[25:1] + 1'b1;
	 log_de = 2'b10;
	 if((exponent_max_in == 8'b11111110) && (~unf_in)) ovf = 1;
   end
   end

   reg [31:0] round_out;
   wire buf_determine;
   assign buf_determine = ovf_in | ovf | unf_in | unf;
   //round the result
   rounder_sub ROUND (
		  .sum_init(sum_init),
		  .clk(clk),
		  .nrst(nrst),
		  .unsigned_exp_diff(unsigned_exp_diff),
		  .frac_in(frac_in),
		  .shifted_frac(shifted_frac),
		  .n1p2r(n1p2r),
		  .wm(wm),
		  .shifted_amount(shifted_amount),
		  .buf_determine(buf_determine),
		  .frac_shifted_minus(frac_shifted_minus),
		  .outallzero(outallzero),
		  .outallone(outallone),
		  .same_compare(same_compare),
		  .shifted_check_onezero(shifted_check_onezero),
		  .shifted_check_allone(shifted_check_allone),
		  .bothnegsub(bothnegsub),
		  .cmp_out(cmp_out),
		  .fp1(floating_point1),
		  .fp2(floating_point2),
		  .frm(frm),
		  .sign(sign_in),
		  .exp_in(exp_out),
		  .carry_out(carry_out),
		  .fraction(round_this),
		  .round_out(round_out),
		  .rounded(round_flag),
		  .sol_frac(rounded_frac)
		  );
   
     assign inexact                  = ovf_in | ovf | unf_in | unf | round_flag;

     assign dummy_floating_point_out[31]   = round_out[31];
     assign dummy_floating_point_out[30:0] = inv    ? signalNaN :
				     ovf_in ? 31'b1111111100000000000000000000000 :
				     ovf    ? 31'b1111111100000000000000000000000 :
				     unf_in ? 31'b0000000000000000000000000000000 :
				     unf    ? 31'b0000000000000000000000000000000 :
				     round_out[30:0];
   
   assign temp_sign = dummy_floating_point_out[31];
   
   always_comb begin
         hold_value  = dummy_floating_point_out;
      if (function_mode == SUB) begin
	 hold_value = {sign_in,dummy_floating_point_out[30:0]};
      end
   end

   always_comb begin
      fp_option = hold_value;
      if (hold_value[30:23] == 8'b11111111) begin
	if (((floating_point1 == Inf) & (floating_point2 == Inf)) | ((floating_point1 == NegInf) & (floating_point2 == NegInf))) begin
		fp_option = hold_value;
        end else begin
		fp_option = {hold_value[31:23], 23'd0};
        end
      end
   end
//determine special cases like operations between Infinity, negitive Infinity, zero, negative zero, quiet NaN, signaling NaN
assign before_floating_point_out = fp_option;
assign {sign, exponent, frac} = before_floating_point_out;
endmodule
