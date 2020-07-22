`timescale 1ns/100ps
module tb_FPU_top_level();
   reg clk = 0;
   reg nrst;
   reg [31:0] floating_point1;
   reg [31:0] floating_point2;
   reg [2:0]  frm;
   reg [31:0] floating_point_out;
   reg [6:0]  funct7;
   reg [4:0]  flags;
   reg start_sig;
   reg f_ready;
   
   always begin
      clk = ~clk;
      #1;
   end

   FPU_top_level DUT (
		      .clk(clk),
		      .nrst(nrst),
		      .floating_point1(floating_point1),
		      .floating_point2(floating_point2),
		      .frm(frm),
		      .funct7(funct7),
		      .floating_point_out(floating_point_out),
		      .flags(flags)
		      );
   
   shortreal        result_real;
   reg  [31:0] result_binary;
   shortreal        fp1_real;
   shortreal        fp2_real;
   shortreal        fp_out_real;
   shortreal        fp_exp;
   shortreal        fp_frac;
   int       i;
   int       j = 0;
   //real val1;
   //shortreal val2;
   task random_check;
      begin
         //$display($bits(val1));
   	 //$display($bits(val2));
         //subnormal number
	 frm = $random() % 8;
	 funct7 = 7'b0000100;
	 floating_point1 = $random();
	 floating_point2 = $random();

	 if(floating_point1[30:23] == 8'b11111111) 
	   floating_point1[30:23] = 8'b11111110;
	 if(floating_point2[30:23] == 8'b11111111) 
	   floating_point2[30:23] = 8'b11111110;

	 //convert from floating point to 2 real values
	 fp_convert(.val(floating_point1), .fp(fp1_real));
	 fp_convert(.val(floating_point2), .fp(fp2_real));

	 //performing real number arithemetic
	 //
	 if(funct7 == 7'b0000000) begin
	    result_real = fp1_real + fp2_real; //addition
	 end else if (funct7 == 7'b0001000) begin
	    result_real = fp1_real * fp2_real; //multiplication
         end else if (funct7 == 7'b0000100) begin
	    result_real = fp1_real - fp2_real; //subtraction
	 end
	 
	 else result_real = 'x;
	 
	 real_to_fp(.r(result_real), .fp(result_binary)); //convert the real number back to floating point
	 @(negedge clk);
	 @(negedge clk);
	 
	 @(negedge clk);
	 fp_convert(.val(floating_point_out), .fp(fp_out_real));
	 #1;
	 assert((floating_point_out == result_binary) || (floating_point_out == result_binary + 1) || (floating_point_out == result_binary - 1)) 
	   else begin
	      j = j + 1;
	      $error("expected = %b, calculated = %b, wrong case = %d, number = %d, fp1 is = %b, fp2 is = %b, result_real is %d", result_binary, floating_point_out, i, j, floating_point1, floating_point2, result_real);
	//$error("expected = %b, calculated = %b, wrong case = %d, number = %d", result_binary, floating_point_out, i, j);
	      //$display(fp1_real);//
	      //$display(fp2_real);//
	      //$display(result_real); //expected
	      //$display(fp_out_real); //computed
	   end
	 //if((flags[1] == 0) & (flags[2] == 0)) begin
	   // assert(flags[0] == 0) else $error("asdklfj;as");
	 //end
	 @(negedge clk);
	 floating_point1 = '0;
	 floating_point2 = '0;
	 frm             = '0;
	 funct7          = '0;
	 result_real     = '0;
	 fp1_real        = '0;
	 fp2_real        = '0;
	 fp_exp          = '0;
	 fp_frac         = '0;
	 @(negedge clk);
	 
      end
   endtask // random_check
   
   task real_to_fp;
      input shortreal r;
      output reg [31:0] fp;
      begin
	 
	 int fp_index;
	 shortreal MAX;
	 shortreal MIN;
	 
	 fp_convert(32'b01111111011111111111111111111111, MAX);
	 fp_convert(32'b00000000000000000000000000000000, MIN);
	 
	 
	 fp = 32'b01000000000000000000000000000000;

	 if(r < 0) begin // set sign bit
	    fp[31] = 1'b1;
	    r = -r;
	 end
	 
	 if(r < MIN) // ovf 
	    fp[30:0] = 31'b0000000000000000000000000000000;
	 
         else if(r > MAX) // unf
	    fp[30:0] = 31'b1111111100000000000000000000000;
	 
	 else begin // everything else
	    if(r >= 2) begin 
	       while(r >= 2) begin
	          r /= 2;
		  fp[30:23] += 1;
	       end
	    end
	    else if(r < 1) begin
	       while(r < 1) begin
		  r *= 2;
		  fp[30:23] -= 1;
	       end
	    end
	    
	    r -= 1;
	    fp_index = 22;
	    for(shortreal i = 0.50; i != 2**-24; i /= 2) begin
	       if(r >= i) begin
		  r -= i;
		  fp[fp_index] = 1'b1;
	       end
	       fp_index -= 1;
	    end
	 end // else: !if((r>(1.70141*(10**38))))
      end
   endtask // real_to_fp
         
   task fp_convert;
      input [31:0] val;
      output shortreal  fp;
      begin
         
	 fp_exp  = shortreal'(val[30:23]);
	 fp_frac = shortreal'(val[22:0]);

	 fp_exp = fp_exp - 128;
	 
	 for(int k = 0; k < 23; k = k + 1) begin
	    fp_frac /= 2;
	 end
     	 fp_frac = fp_frac + 1;	 

	 if(val[31]) 
	   fp = -fp_frac * (2 ** fp_exp);
	 else
	   fp = fp_frac * (2 ** fp_exp);
      end
   endtask // fp_convert

task reset_dut;
  begin
  nrst = 1'b0;

  @(posedge clk);
  @(posedge clk);

  @(negedge clk);
  nrst = 1'b1;

  @(negedge clk);
  @(negedge clk);
  end
endtask

initial begin
   reset_dut();
   i = 0;
//random_check();
   while (1) begin
	reset_dut();
	i = i + 1;
	random_check();
  end //
end
   
endmodule // tb_FPU_top_level
