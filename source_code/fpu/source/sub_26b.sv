//By            : Joe Nasti
//Modified by   : Xinlue Liu
//Last Updated  : 6/1/20
//
//Module Summary: 
//    adds two signed 26 bit fraction values
//
//Inputs:
//    frac1/2 - signed 26 bit values with decimal point fixed after second bit
//    frac1_s/frac2_s - 2's complements of the two floating points
//    exp_determine - signal indicator that indicates which subtraction operation it is going to perform
//Outputs:
//    sum     - output of sum operation regardless of overflow
//    ovf     - high if an overflow has occured 
 
module sub_26b(
	input reg n1p2r,
	input reg shifted_check_onezero,
	input      [31:0] fp1,
	input      [31:0] fp2,
	input 	   cmp_out,
	input      [26:0] frac1,
	input      [26:0] frac2,
	input      [26:0] frac1_s,
	input      [26:0] frac2_s,
	input reg n1p2,
	input reg  bothpossub,
	//input reg exp_determine,
	output reg [26:0] sum, 
	output reg        ovf,
	output reg        outallone,
	output reg 	  outallzero,
	output reg    [2:0]    wm,
	output reg sum_init
);
   always_comb begin : check_frac1_one
	outallone = 1'b0;
	outallzero = 1'b0;
	if (frac1 == 27'b111111111111111111111111111)
		outallone = 1'b1;
	if ((frac1 == 0) & (fp1[31] == 0) & (fp2[31] == 0)) 
		outallzero = 1'b1;
		  //tallzero = 1'b0;
   end
always_comb begin
   wm = 0;
   if ((bothpossub == 0) & (n1p2 == 0) & (cmp_out == 0))begin
   	sum = frac1 + frac2;
  	wm = 3'b001;
   end else begin
   	sum = frac1_s + frac2_s;
   	//sum = ~temp_sum + 1'b1;
        wm = 3'b010;
	//sum 00001101010011101110001110
   end
   sum_init = sum[26];
   ovf = 0;
   if ((bothpossub == 0) & (n1p2 == 0) & (cmp_out == 0)) begin
     //if (bothpossub == 0) begin
  	 if(frac1[26] == 1 && frac2[26]== 1 && sum[26] == 0) begin
     	 	ovf = 1;
     	 	sum[26] = 1;
   	 end
   
   	 if(frac1[26] == 0 && frac2[26]== 0 && sum[26] == 1) begin
     		ovf = 1;
     		sum[26] = 0;
   	 end
   /*end else if ((bothpossub == 0) & (n1p2 == 0) & (cmp_out == 1))begin
  	 if(frac1_s2[26] == 1 && frac2[26]== 1 && sum[26] == 0) begin
     	 	ovf = 1;
     	 	sum[26] = 1;
   	 end
   
   	 if(frac1_s2[26] == 0 && frac2[26]== 0 && sum[26] == 1) begin
     		ovf = 1;
     		sum[26] = 0;
   	 end*/
   end else begin
   	if(frac1_s[26] == 1 && frac2_s[26]== 1 && sum[26] == 0) begin
      		ovf = 1;
      		sum[26] = 1;
   	end
   
   	if(frac1_s[26] == 0 && frac2_s[26]== 0 && sum[26] == 1) begin
      		ovf = 1;
      		sum[26] = 0;
   	end
  end
end
endmodule


