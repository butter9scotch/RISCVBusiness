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
	input      [26:0] frac1_orig,
	input      [26:0] frac2_origcomp,
	input 	   [26:0] frac1_s2,
	input 	   cmp_out,
	input      [26:0] frac1,
	input      [26:0] frac2,
	input      [26:0] frac1_s,
	input      [26:0] frac2_s,
	input reg n1p2,
	input reg  bothpossub,
	//input reg exp_determine,
	output reg [26:0] sum, 
	output reg        ovf
);
   reg [26:0] 		  frac1_compute;
   reg [26:0] 		  frac2_compute;
   reg [26:0] 		  temp_sum;
   
always_comb begin
   if ((bothpossub == 0) & (n1p2 == 0) & (cmp_out == 0))begin
   	sum = frac1 + frac2;
   /*end else if ((bothpossub == 0) & (n1p2 == 0) & (cmp_out == 1))begin
	temp_sum = frac1_s2 + frac2;
	sum = ~temp_sum + 1'b1;*/
   end else if (n1p2 == 1) begin
	sum = frac1_s + frac2_s;
   end else begin
   	temp_sum = frac1_s + frac2_s;
   	sum = ~temp_sum + 1'b1;
   end
   
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


