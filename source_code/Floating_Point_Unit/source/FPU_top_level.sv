//By            : Joe Nasti
//Edited by 		: Xinlue Liu, Zhengsen Fu
//Last Updated  : 7/15/2020
//
//Module Summary:
//    Three-stage floating point unit supporting operations:
//    addition
//    subtraction (in progress)
//    multiplication 
//
//Inputs:
//    clk                - system clock
//    nrst               - active low reset
//    floating_point1/2  - floating points to be operated on
//    frm                - rounding mode
//    funct7             - 7 bit operation code
//Outputs:
//    floating_point_out - result of operation 
//    flags              - 5 error flags (overflow,  underflow, divide by zero, inexact result, invalid operation)

module FPU_top_level
(
 input 	       clk,
 input 	       nrst,
 input  [31:0] floating_point1,
 input  [31:0] floating_point2,
 input  [2:0]  frm,
 input  [6:0]  funct7,
 output [31:0] floating_point_out,
	output 			 f_stall,
 output [4:0]  flags
 );
   //reg [2:0]   cycle_count;
   reg [2:0]   frm2;
   reg [2:0]   frm3;
   reg [6:0]   funct7_2;
   reg [6:0]   funct7_3;

   //funct7 definitions
   localparam ADD = 7'b0000000;
   localparam MUL = 7'b0001000;
   localparam SUB = 7'b0000100; 


   
   reg 	       sign_shifted;
   reg         sign_shifted_minus;
   reg [25:0]  frac_shifted;
   reg [25:0]  frac_shifted_minus;
   
   reg 	       sign_not_shifted;
   reg         sign_not_shifted_minus;
   reg [25:0]  frac_not_shifted;
   reg [25:0]  frac_not_shifted_minus;
   reg [7:0]   exp_max;
   reg [7:0]   exp_max_minus;
   
   reg         mul_sign1;
   reg         mul_sign2;
   reg [7:0]   mul_exp1;
   reg [7:0]   mul_exp2;
   reg [25:0]  product;
   reg         mul_carry_out;
   logic 		   out_of_range;
   
   reg [61:0]  step1_to_step2;
   reg [61:0]  nxt_step1_to_step2;
   
   
   reg        add_sign_out;
   reg [25:0] add_sum;
   reg 	      add_carry_out;
   reg [7:0]  add_exp_max;


   reg        minus_sign_out;
   reg [25:0] minus_sum;
   reg        minus_carry_out;
   reg [7:0]  minus_exp_max;
   reg        cmp_out;
   reg 	      cmp_out_det;
   reg        fp1_sign;
   reg [25:0] fp1_frac;
   reg        fp2_sign;
   reg [25:0] fp2_frac;

   // MUL step2 outputs -> step3 inputs
   reg        mul_sign_out;
   reg [7:0]  sum_exp;
   reg        mul_ovf;
   reg        mul_unf;

   // invalid operation flag
   reg        inv;
   reg        inv2;
   reg        inv3;  

   reg [37:0] step2_to_step3;
   reg [37:0] nxt_step2_to_step3;
   reg exp_determine;
   reg bothnegsub;
   reg bothpossub;
   reg 	      n1p2;
   reg 	      n1p2r;
   reg 	      signout;
   reg 	      same_compare;
   reg 	      shifted_check_allone;
   reg 	      shifted_check_onezero;
   reg  [7:0] 	 unsigned_exp_diff;
   reg        frac_same;
   reg [2:0] wm;
   reg        ovf;
   reg        unf;
   reg        inexact;
   reg        ovf_sub;
   reg        unf_sub;
   reg        inexact_sub;
   reg [4:0] flag_add;
   reg [4:0] flag_sub;
   reg sum_init;

	determine_frac_status determine_frac_status (
			      .fp1_frac1(floating_point1[22:0]),
			      .fp2_frac2(floating_point2[22:0]),
			      .frac_same(frac_same)
				);

 	int_comparesub cmp_exponent (
			      .exp1(floating_point1[30:23]), 
			      .exp2(floating_point2[30:23]),
			      .cmp_out(cmp_out_det),
			      .same_compare(same_compare)
			      );

	sign_determine sign_determine (
					.same_compare(same_compare),
				        .frac_same(frac_same),
					.cmp_out(cmp_out_det),
					.floating_point1(floating_point1),
					.floating_point2(floating_point2),
					.signout(signout)
					);

	always_comb begin : check_neg_size
		bothnegsub = 0;
		if (((floating_point1[31]==1) && (floating_point2[31]==1) && (cmp_out_det==1) && (funct7 == SUB)) | ((funct7 == SUB) & ((floating_point1[31] == 1) & (floating_point2[31] == 1) & (same_compare == 1)) 
	& (frac_same == 1))) begin
			bothnegsub = 1;
		end
	end

	always_comb begin : check_pos_size
		bothpossub = 0;
		if ((floating_point1[31]==0) && (floating_point2[31]==0) && (cmp_out_det==1) && (funct7 == SUB)) begin
			bothpossub = 1;
		end
	end

always_comb begin : check_n1p2_size
		n1p2 = 0; 
		if (((floating_point1[31]==0) && (floating_point2[31]==1) && (cmp_out_det==1) && (funct7 == SUB))) begin
			n1p2 = 1;
		end
	end

always_comb begin : check_n1p2r_size
		n1p2r = 0; 
		if ((floating_point1[31]==1) && (floating_point2[31]==0) && (cmp_out_det==1) && (funct7 == SUB)) begin
			n1p2r = 1;
		end
	end


        //first step of addition. determine the exponent and fraction of the floating point that needs to be shifted
	ADD_step1 addStep1(
			   .funct7(funct7),
			   .floating_point1_in(floating_point1),
			   .floating_point2_in(floating_point2),
			   .sign_shifted(sign_shifted),
			   .frac_shifted(frac_shifted),
			   .sign_not_shifted(sign_not_shifted),
			   .frac_not_shifted(frac_not_shifted),
			   .exp_max(exp_max)
			   );

	//first step of subtraction. determine the exponent and fraction of the floating point that needs to be shifted
        SUB_step1 substep1(
			   .funct7(funct7),
			   .bothnegsub(bothnegsub),
		      	   .floating_point1_in(floating_point1),
			   //.floating_point2_in({~floating_point2[31], floating_point2[30:0]}),
			   .floating_point2_in(floating_point2),
			   .sign_shifted(sign_shifted_minus),
			   .frac_shifted(frac_shifted_minus),
			   .sign_not_shifted(sign_not_shifted_minus),
			   .frac_not_shifted(frac_not_shifted_minus),
			   .exp_max(exp_max_minus),
			   .cmp(cmp_out),
			   .unsigned_exp_diff(unsigned_exp_diff)
		           );

   
// first step of multiplication. multiply two floating points
        MUL_step1 mulStep1(
			   .fp1_in(floating_point1),
			   .fp2_in(floating_point2),
			   .sign1(mul_sign1),
			   .sign2(mul_sign2),
			   .exp1(mul_exp1),
			   .exp2(mul_exp2),
			   .product(product),
			   .carry_out(mul_carry_out),
			   .out_of_range(out_of_range)
			   );
   
   
   always_comb begin : check_for_invalid_op
      inv = 0;
      // checking for invalid operation. Subject to change
      if ((funct7 == ADD) || (funct7 == SUB)) begin
	 if((floating_point1[30:0] == 31'h7F800000) && 
	    (floating_point2[30:0] == 31'h7F800000) && 
	    (floating_point1[31] ^ floating_point2[31])) begin
	        inv = 1;
	 end
      end
      
      if(funct7 == MUL) begin
	 if(((floating_point1[30:0] == 31'h00000000)  &&
	     (floating_point2[30:0] == 31'h7F800000)) ||
	    ((floating_point1[30:0] == 31'h7F800000)  &&
	     (floating_point2[30:0] == 31'h00000000))) begin
	        inv = 1;
	 end
      end
   end // block: check_for_invalid_op

	// add signal indicator that indicates which subtraction operation it is going to perform
	always_comb begin: determine_exp
	if (cmp_out == 0) begin //fp1 > fp2.
		exp_determine = 1'b1;
	end else if (cmp_out == 1) begin
		exp_determine = 1'b0;
	end
	end

   //reorder the two floating points to pass into the second block of the subtraction routine
   always_comb begin: reorder_the_subtraction
	fp1_sign = 0;
	fp1_frac = 0;
	fp2_sign = 0;
	fp2_frac = 0;
   //if (bothnegsub == 0) begin
   	if (cmp_out == 0) begin //if fp1 >= fp2
      		fp1_sign = sign_not_shifted_minus;
      		fp1_frac = frac_not_shifted_minus;
      		fp2_sign = sign_shifted_minus;
      		fp2_frac = frac_shifted_minus;
   	end else if (cmp_out == 1) begin
      		fp1_sign = sign_shifted_minus;
      		fp1_frac = frac_shifted_minus;
      		fp2_sign = sign_not_shifted_minus;
      		fp2_frac = frac_not_shifted_minus; 
   	end
   end
	always_comb begin : check_shifted_frac_allone
		shifted_check_allone = 0;
		if ((floating_point1[31]==1) && (floating_point2[31]== 1) && (frac_shifted_minus==0) && (funct7 == SUB)) 	begin
			shifted_check_allone = 1;
		end
	end

always_comb begin : check_shifted_frac_onezero
		shifted_check_onezero = 0;
		if ((floating_point1[31]==1) && (floating_point2[31]== 0) && (frac_shifted_minus==0) && (funct7 == SUB)) 	begin
			shifted_check_onezero = 1;
		end
	end

   always_comb begin : select_op_step1to2
	nxt_step1_to_step2 = 0;
      case(funct7)
	ADD: begin
	   nxt_step1_to_step2[61]    = sign_shifted;
	   nxt_step1_to_step2[60:35] = frac_shifted;
	   nxt_step1_to_step2[34]    = sign_not_shifted;
	   nxt_step1_to_step2[33:8]  = frac_not_shifted; 
	   nxt_step1_to_step2[7:0]   = exp_max;
	end
	SUB: begin
	   nxt_step1_to_step2[61]   = fp1_sign;
	   nxt_step1_to_step2[60:35] = fp1_frac;
	   nxt_step1_to_step2[34]    = fp2_sign;
	   nxt_step1_to_step2[33:8]  = fp2_frac;
	   nxt_step1_to_step2[7:0]   = exp_max_minus;
	end
	MUL: begin
	   nxt_step1_to_step2[61]    = mul_sign1;
	   nxt_step1_to_step2[60]    = mul_sign2;
           nxt_step1_to_step2[59:52] = mul_exp1;
	   nxt_step1_to_step2[51:44] = mul_exp2;
	   nxt_step1_to_step2[43:18] = product;
	   nxt_step1_to_step2[17]    = mul_carry_out;
	end
     
      endcase // case (funct7)
   end // block: select_op
   			       
   always_ff @ (posedge clk, negedge nrst) begin : STEP1_to_STEP2
      if(nrst == 0) begin
        frm2           <= 0;
	 			step1_to_step2 <= 0;
        funct7_2       <= 0;
	 			inv2           <= 0;
      end
      else begin
        frm2           <= frm;
	 			step1_to_step2 <= nxt_step1_to_step2;
	 			funct7_2       <= funct7;
	 			inv2           <= inv;
      end
   end 
	 //perform addition
	  ADD_step2 add_step2 (
			      .frac1(step1_to_step2[60:35]),    // frac_shifted
			      .sign1(step1_to_step2[61]),       // sign_shifted
			      .frac2(step1_to_step2[33:8]),     // frac_not_shhifted
			      .sign2(step1_to_step2[34]),       // sign_not_shifted
			      .exp_max_in(step1_to_step2[7:0]), // exp_max
			      .sign_out(add_sign_out),
			      .sum(add_sum),
			      .carry_out(add_carry_out),
			      .exp_max_out(add_exp_max)
			      );
	 //perform subtraction
          SUB_step2 sub_step2 (
			      .n1p2r(n1p2r),
			      .shifted_check_onezero(shifted_check_onezero),
			      .fp1(floating_point1),
			      .fp2(floating_point2),
	 		      .cmp_out(cmp_out),
	   		      .n1p2(n1p2),
		  	      .bothnegsub(bothnegsub),
			      .bothpossub(bothpossub),
			      .frac1(step1_to_step2[60:35]),    // frac_shifted
			      .sign1(step1_to_step2[61]),       // sign_shifted
			      .frac2(step1_to_step2[33:8]),     // frac_not_shhifted
			      .sign2(step1_to_step2[34]),       // sign_not_shifted
			      .exp_max_in(step1_to_step2[7:0]), // exp_max
			      .sign_out(minus_sign_out),
			      .sum(minus_sum),
			      .carry_out(minus_carry_out),
			      .exp_max_out(minus_exp_max),
			      .exp_determine(exp_determine),
			      .outallone(outallone),
			      .outallzero(outallzero),
			      .wm(wm),
			      .sum_init(sum_init)
			      );
   
         MUL_step2 mul_step2 (
			      .sign1(step1_to_step2[61]),   // mul_sign1
			      .sign2(step1_to_step2[60]),   // mul_sign2
			      .exp1(step1_to_step2[59:52]), // mul_exp1
			      .exp2(step1_to_step2[51:44]), // mul_exp2
			      .sign_out(mul_sign_out),
			      .sum_exp(sum_exp),
			      .ovf(mul_ovf),
			      .unf(mul_unf),
			      .carry(step1_to_step2[17])
			      );
   
   always_comb begin : select_op_step2to3
      nxt_step2_to_step3 = 0;
      case(funct7_2)
	ADD: begin
	   nxt_step2_to_step3[37:36]= 2'b00;
	   nxt_step2_to_step3[35]   = add_sign_out;
	   nxt_step2_to_step3[34:9] = add_sum;
	   nxt_step2_to_step3[8]    = add_carry_out;
	   nxt_step2_to_step3[7:0]  = add_exp_max;
	end
	MUL: begin
	   nxt_step2_to_step3[37]   = mul_ovf;
       	   nxt_step2_to_step3[36]   = mul_unf;	      
	   nxt_step2_to_step3[35]   = mul_sign_out;
	   nxt_step2_to_step3[34:9] = step1_to_step2[43:18]; // product from MUL_step1
	   nxt_step2_to_step3[8]    = step1_to_step2[17];    // mul_carry_out;
	   nxt_step2_to_step3[7:0]  = sum_exp;
	end
	SUB: begin
	   nxt_step2_to_step3[37:36]= 2'b00;
	   nxt_step2_to_step3[35]   = minus_sign_out;
	   nxt_step2_to_step3[34:9] = minus_sum;
	   nxt_step2_to_step3[8]    = minus_carry_out;
	   nxt_step2_to_step3[7:0]  = minus_exp_max;
	end
      endcase // case (funct7_2)
   end // block: select_op_step2to3
   
   
   always_ff @ (posedge clk, negedge nrst) begin : STEP2_to_STEP3
      if(nrst == 0) begin
	 				funct7_3       <= 0;
   	      step2_to_step3 <= 0;
	 				frm3           <= 0;
	 				inv3           <= 0;
      end
      else begin
	 				funct7_3       <= funct7_2;
	 				step2_to_step3 <= nxt_step2_to_step3;
	 				frm3           <= frm2;
	 				inv3           <= inv2;
      end 
   end  
   reg o;

   always_comb begin
      o = 0;
      if((step2_to_step3[7:0] == 8'b11111111) && (step2_to_step3[36] == 1'b0) && (step2_to_step3[8] == 0)) o = 1;
      else o = step2_to_step3[37]; 
   end

   reg [31:0] negmul_floating_point_out;
   reg [31:0] add_floating_point_out;
   //round the results and perform special case checking
   SUB_step3 sub_step3 (
		    .sum_init(sum_init),
		    .unsigned_exp_diff(unsigned_exp_diff),
		    .n1p2r(n1p2r),
		    .wm(wm),
		    .clk(clk),
		    .nrst(nrst),
		    .frac_shifted_minus(frac_shifted_minus),
		    .outallzero(outallzero),
	 	    .outallone(outallone),
		    .same_compare(same_compare),
		    .shifted_check_allone(shifted_check_allone),
		    .shifted_check_onezero(shifted_check_onezero),
	 	    //.signout(signout),
		    .bothnegsub(bothnegsub),
		    .cmp_out(cmp_out),
		    .floating_point1(floating_point1),
		    .floating_point2(floating_point2),
		    .function_mode(funct7_3[6:0]),
		    .ovf_in(o),
		    .unf_in(step2_to_step3[36]),
		    .dz(1'b0),
		    .inv(inv3),
		    .frm(frm3),
		    .exponent_max_in(step2_to_step3[7:0]),
		    //.sign_in(step2_to_step3[35]),
		    .sign_in(signout),
		    .frac_in(step2_to_step3[34:9]),
		    .carry_out(step2_to_step3[8]),
		    .before_floating_point_out(negmul_floating_point_out),
		    .ovf(ovf_sub),
		    .unf(unf_sub),
		    .inexact(inexact_sub)
		    //.flags(flags)
		    );
//round the results 
   ADD_step3 add_step3 (
	   		.out_of_range(out_of_range),
		    .mul_ovf(mul_ovf),
		    .mul_carry_out(mul_carry_out),
		    .function_mode(funct7_3[6:0]),
		    .floating_point1(floating_point1),
		    .floating_point2(floating_point2),
		    .ovf_in(o),
		    .unf_in(step2_to_step3[36]),
		    .dz(1'b0),
		    .inv(inv3),
		    .frm(frm3),
		    .exponent_max_in(step2_to_step3[7:0]),
		    .sign_in(step2_to_step3[35]),
		    .frac_in(step2_to_step3[34:9]),
		    .carry_out(step2_to_step3[8]),
		    .add_floating_point_out(add_floating_point_out),
		    .ovf(ovf),
		    .unf(unf),
		    .inexact(inexact)
		    );


always_ff @ (posedge clk, negedge nrst) begin: delay_flags
	if (nrst == 0) begin
		flag_add <= 0;
		flag_sub <= 0;
	end else begin
		flag_add   <= {inv, 1'b0, (ovf | o), (unf | o), inexact};
		flag_sub   <= {inv, 1'b0, (ovf_sub | o), (unf_sub | o), inexact_sub};
	end
end

assign floating_point_out = (funct7 == SUB) ? negmul_floating_point_out : add_floating_point_out;
assign flags = (funct7 == SUB) ? flag_sub : flag_add;

endmodule
