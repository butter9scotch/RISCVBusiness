//By            : Joe Nasti
//Last Updated  : 7/23/18
//
//Module Summary:
//    First step of multiplication in three-step pipeline.
//    multiplies 26 bit fractions
//
//Inputs:
//    fp1/2     - single precision floating points
//Outputs:
//    sign1/2   - signs of floating points
//    exp1/2    - exponents of floating points
//    product   - result of fraction multiplication
//    carry_out - signal if there is a carry out of the multiplication

module MUL_step1
  (
   input  [31:0] fp1_in,
   input  [31:0] fp2_in,
   output        sign1,
   output        sign2,
   output [7:0]  exp1,
   output [7:0]  exp2,
   output [25:0] product,
   output        carry_out,
   output reg out_of_range
   );

   assign sign1 = fp1_in[31];
   assign sign2 = fp2_in[31];
   assign exp1  = fp1_in[30:23];
   assign exp2  = fp2_in[30:23];
   //multiply the two numbers

   reg [28:0] test_mul_frac;
   assign test_mul_frac = fp1_in[22:0] * fp2_in[22:0];
   reg [9:0] test_mul_exp;
   assign test_mul_exp = fp1_in[30:23] + fp2_in[30:23];
   //reg out_of_range;

   always_comb begin
     out_of_range = 1'b0;
     if (test_mul_exp == 9'b0101111111)
      out_of_range = 1'b1;
   end

   mul_26b MUL (
		.frac_in1({1'b1, fp1_in[22:0], 2'b00}),
		.frac_in2({1'b1, fp2_in[22:0], 2'b00}),
		.frac_out(product),
		.overflow(carry_out)
		);

endmodule // MUL_step1


   
