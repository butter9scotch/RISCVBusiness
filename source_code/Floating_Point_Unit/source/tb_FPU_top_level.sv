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
   real val1;
   shortreal val2;
   
   task random_check;
      begin
         //$display($bits(val1));
   	 //$display($bits(val2));
  //subnormal number
	 frm       = $random() % 8;
	 funct7 = 7'b0100100;
	 floating_point1 = $random();
	 floating_point2 = $random();
	 /*if (i == 0) begin
	 floating_point1 = 32'b01000001000111000000000000000000; //9.75
	 floating_point2 = 32'b00111111000100000000000000000000; //0.5625
	 end else if (i == 1) begin
         floating_point1 = 32'b01000010101110010110011001100110; //92.7
	 floating_point2 = 32'b01000001110110110011001100110011; //27.4
	 end else if (i == 2) begin
	 floating_point1 = 32'b01000101100011110101110101100010; //4587.673
         floating_point2 = 32'b01000011111100111101011000101011; //487.6732
	 end else if (i == 3) begin
	 floating_point1 = 32'b01001011000100110011000110001111; //9646479.12357
         floating_point2 = 32'b01000111111100010010011111010110; //123471.6732
	 end else if (i == 4) begin
	 floating_point1 = 32'b01000111001101101011010001101010; //46772.414
         floating_point2 = 32'b01000101000100111111011001100110; //2367.4
	 end else if (i == 5) begin
         floating_point1 = 32'b11000001000111000000000000000000; //-9.75
	 floating_point2 = 32'b10111111000100000000000000000000; //-0.5625
	 end else if (i == 6) begin
         floating_point1 = 32'b11000010101110010110011001100110; //-92.7
	 floating_point2 = 32'b11000001110110110011001100110011; //-27.4
	 end else if (i == 7) begin
	 floating_point1 = 32'b11000101100011110101110101100010; //-4587.673
         floating_point2 = 32'b11000011111100111101011000101011; //-487.6732
	 end else if (i == 8) begin
	 floating_point1 = 32'b11001011000100110011000110001111; //-9646479.12357
         floating_point2 = 32'b11000111111100010010011111010110; //-123471.6732
	 end else if (i == 9) begin
	 floating_point1 = 32'b11000111001101101011010001101010; //-46772.414
         floating_point2 = 32'b11000101000100111111011001100110; //-2367.4
	 end else if (i == 10) begin
	 floating_point1 = 32'b00111111000100000000000000000000; //0.5625
         floating_point2 = 32'b01000001000111000000000000000000; //9.75
	 //Error: expected = 1 10000010 00100110000000000000000, 
	 //     calculated = 1 10000010 00010100000000000000000, frac1 + frac2

	 //Error: expected = 1 10000010  00100110000000000000000, 
	 //     calculated = 1 10000010 00010100000000000000000,
	 end else if (i == 11) begin
	 floating_point1 = 32'b01000001110110110011001100110011; //27.4
         floating_point2 = 32'b01000010101110010110011001100110; //92.7
	 //Error: expected = 1 10000101 00000101001100110011001, 
	 //     calculated = 1 10000101 10010111100110011001100
	 end else if (i == 12) begin
         floating_point1 = 32'b01000011111100111101011000101011; //487.6732
	 floating_point2 = 32'b01000101100011110101110101100010; //4587.673
	 //Error: expected = 1 10001011 00000000001111111111111, 
	 //     calculated = 1 10001011 11100001110001010011100,
	 end else if (i == 13) begin
         floating_point1 = 32'b01000111111100010010011111010110; //123471.6732
	 floating_point2 = 32'b01001011000100110011000110001111; //9646479.12357
	 //Error: expected = 1 10010110 00100010100111100111111, 
	 //     calculated = 1 10010110 00011110110110011110000
	 end else if (i == 14) begin
         floating_point1 = 32'b01000101000100111111011001100110; //2367.4
	 floating_point2 = 32'b01000111001101101011010001101010; //46772.414
	 //Error: expected = 1 10001110 01011010111010100000011, 
 	 //     calculated = 1 10001110 01001000011010110011101
	 end else if (i == 15) begin
	 floating_point1 = 32'b00111110100000000000000000000000; //.25
	 floating_point2 = 32'b01000010110010000000000000000000; //100
	 //Error: expected = 1 10000101 10001111000000000000000, 
	 //	calculated = 1 10000101 10001110000000000000000
	 end else if (i == 16) begin
	 floating_point1 = 32'b11000001110110110011001100110011; //-27.4
         floating_point2 = 32'b11000010101110010110011001100110; //-92.7
	 end else if (i == 17) begin
	 floating_point1 = 32'b11000101000100100011011001100110; //-2367.3999
	 floating_point2 = 32'b11000111001110101011010101101010; //-46773.4141
	 end else if (i == 18) begin
         floating_point1 = 32'b11000010100100011111111101111101; //-72.999
	 floating_point2 = 32'b11001110001100100110011001001001; //-748261946.14893
	 end else if (i == 19) begin
	 floating_point1 = 32'b11000010110101101101011100001010; //-107.42
	 floating_point2 = 32'b11000111101110111110011110001110; //-96207.111
	 end else if (i == 20) begin
	 floating_point1 = 32'b10111111000100000000000000000000; //-0.5625
         floating_point2 = 32'b11000001000111000000000000000000; //-9.75
	 end else if (i == 21) begin
	 floating_point1 = 32'b01111111100000000000000000000000; //Inf
	 floating_point2 = 32'b11000010101010000011011111001111; //-94.109
 	 end else if (i == 22) begin
         floating_point1 = 32'b11111111100000000000000000000000; //-Inf
	 floating_point2 = 32'b11000001000001101001001100001100; //-8.4109
	 end else if (i == 23) begin
	 floating_point1 = 32'b11000010101010000011011111001111; //-94.109
	 floating_point2 = 32'b01111111100000000000000000000000; //Inf
 	 end else if (i == 24) begin
         floating_point1 = 32'b11000001000001101001001100001100; //-8.4109
	 floating_point2 = 32'b11111111100000000000000000000000; //-Inf
	 end else if (i == 25) begin
	 floating_point1 = 32'b11000010101010000011011111001111; //-94.109
	 floating_point2 = 32'b10000000000000000000000000000000; //-0
 	 end else if (i == 26) begin
         floating_point1 = 32'b11000010101010000011011111001111; //-94.109
	 floating_point2 = 32'b00000000000000000000000000000000; //0
	 end else if (i == 27) begin
	 floating_point1 = 32'b11111111100000000000000000000000; //-Inf
	 floating_point2 = 32'b10000000000000000000000000000000; //-0
 	 end else if (i == 28) begin
	 floating_point1 = 32'b10000000000000000000000000000000; //-0
	 floating_point2 = 32'b11000010101110010110011001100110; //-92.7
 	 end else if (i == 29) begin
	 floating_point1 = 32'b00000000000000000000000000000000; //0
	 floating_point2 = 32'b11000010101110010110011001100110; //-92.7
	 //end else if (i == 30) begin
         //floating_point1 = 32'b01111111110000000000000000000000; //qNaN
	 //floating_point2 = 32'b11000001000001101001001100001100; //-8.4109
	 end else if (i == 30) begin
         floating_point1 = 32'b11000000100010010101111010000001; //-4.29
	 floating_point2 = 32'b10000100100001001101011000001001; //-3.13e-36
	 end else if (i == 31) begin
         floating_point1 = 32'b01100000101100010111010111000001; //1.023e20
	 floating_point2 = 32'b11100010111001010111010011000101; //-2.11636e21
	 //Error: expected = 0 11000101 11100001000110000100001, 
	 //	calculated = 0 11000101 11110111010001101111101 sum = frac1 + frac2;
	 //	calculated = 0 11000101 11100001000110000100001 sum = frac1_s + frac2_s; kkk
	 //	calculated = 0 11000101 00001111011100111110000 sum[26:0] = ~temp_sum[26:0] + 1'b1; signed
	 //	calculated = 0 11000101 00000100010111001000010 sum[26:0] = ~temp_sum[26:0] + 1'b1; unsigned
         end else if (i == 32) begin
         floating_point1 = 32'b01010101011110000100010110101010; //1.71e13
	 floating_point2 = 32'b11001110110011001100110010011101; //-1717980800
	 end else if (i == 33) begin
         floating_point1 = 32'b01100011010010111111100111000110; //3.763e21
	 floating_point2 = 32'b01010111000101010001001110101110; //1.639e14
	 end else if (i == 34) begin
         floating_point1 = 32'b00110101100111111101110101101011; //1.19e-6
	 floating_point2 = 32'b11101010101001100010101011010101; //-1.0044e26
 	 end else if (i == 35) begin
         floating_point1 = 32'b00000101011100111000011100001010; //1.145e-35
	 floating_point2 = 32'b11000000001110110010001010000000; //-2.924
	 end else if (i == 36) begin
         floating_point1 = 32'b00100000110001001011001101000001; //3.332e-19
	 floating_point2 = 32'b11101100010010110011010011011000; //-9.83e26
	 end else if (i == 37) begin
         floating_point1 = 32'b10001101001001001111011000011010; //-5.08e-31
	 floating_point2 = 32'b11011100111100000000000010111001; //-5.4e17 //
	 //			frac in 1110000000000001011100100
	 //Error: expected = 0 10111001 11100000000000010111001, 
	 //	calculated = 0 10111000  11000000000000101110010,
	 end else if (i == 38) begin
         floating_point1 = 32'b10011100011011011110011000111000; //-7.87e-22
	 floating_point2 = 32'b10111100110011111010100001111001; //-0.0253488887101 //
	 //			frac in 1001111101010000111100100
	 //Error: expected = 0 01111001 10011111010100001111001, 
	 //	calculated = 0 01111000  00111110101000011110010,
	 end else if (i == 39) begin
         floating_point1 = 32'b10111010101100010100100001110101; //-0.00135256221984
	 floating_point2 = 32'b11000111111010000101011010001111; //-118957.117188 //
	 //			frac in 1101000010101101000111100
	 //Error: expected = 0 10001111 11010000101011010001110, 
	 //	calculated = 0 10001110  10100001010110100011110
	 end else if (i == 40) begin
         floating_point1 = 32'b10110110101001000010011001101101; //-4.89e-6
	 floating_point2 = 32'b10111011010001011110001001110110; //-0.00302 /////////////////
	 //			frac in 1000101100100000110001100
	 //Error: expected = 0 01110110 10001011001000001100010,      this
	 //	calculated = 0 01110101  00010110010000011000110,


	 //Error: expected = 0 01110110 10001011001000001100010, 
	 //	calculated = 0 01110101  00010110010000011000110
	 end else if (i == 41) begin
         floating_point1 = 32'b11001101010111101011110010011010; //-233556384
	 floating_point2 = 32'b11111110110111110111001011111101; //-1.485e38 //
	 //			frac in 1011111011100101111110100
	 //Error: expected = 0 11111101 10111110111001011111101, 
	 //	calculated = 0 11111100  01111101110010111111010
	 end else if (i == 42) begin
         floating_point1 = 32'b10010111100110011010100000101111; //-9.93e-25
	 floating_point2 = 32'b11011001110100101001001010110011; //-7.41e15 //
	 //Error: expected = 0 10110011 10100101001001010110011, 
	 //	calculated = 0 10110010  01001010010010101100110
	 end else if (i == 43) begin
         floating_point1 = 32'b10010110100100000000010000101101; //-2.3267e-25
	 floating_point2 = 32'b11100011110001010011000011000111; //-7.275e21 //
	 //Error: expected = 0 11000111 10001010011000011000111, 
	 //	calculated = 0 11000110  00010100110000110001110
	 end else if (i == 44) begin
         floating_point1 = 32'b11001111011000111101101010011110; //-3822755328.0
	 floating_point2 = 32'b11111110111100000110010011111101; //-1.5977e+38 //
	 //Error: expected = 0 11111101 11100000110010011111101, 
	 //	calculated = 0 11111100  11000001100100111111010,
	 end else if (i == 45) begin
         floating_point1 = 32'b10111000010101011100010001110000; //-5.0966e-5
	 floating_point2 = 32'b10111001111101010000010001110011; //-0.000467333564302 ////////////////
	 //Error: expected = 0 01110011 10110100100101111100101, 
	 //	calculated = 0 01110010  01101001001011111001010

	 //Error: expected = 0 01110011 10110100100101111100101, 
	 //	calculated = 0 01110010  01101001001011111001010
	 end else if (i == 46) begin
         floating_point1 = 32'b10001001001101110101001000010010; //-2.21e-33
	 floating_point2 = 32'b00000000111100111110001100000001; //2.24e-38 
	 end else if (i == 47) begin
         floating_point1 = 32'b10011110001100010100110000111100; //-9.386e-21
	 floating_point2 = 32'b01111001011010001011110111110010; //7.553e34 
	 end else if (i == 48) begin
         floating_point1 = 32'b11000100100010100001001010001001; //-1104.579
	 floating_point2 = 32'b01110101110001010000110111101011; //4.996e32 
	 end /*else if (i == 49) begin //01
         floating_point1 = 32'b00010011101011101111000100100111; //4.41615697729e-27
	 floating_point2 = 32'b10010011111001010010001000100111; //-5.78414039456e-27
	 //  expected = 0 00101000 10010100000100110100111, 
	 //calculated = 0 00100111 10010100000100110100111
	 end else if (i == 50) begin //01
         floating_point1 = 32'b00100100011011011110011101001000; //5.15870858146e-17
	 floating_point2 = 32'b10100101111011100101001001001011; //-4.13421826129e-16
	 //Error: expected = 0 01001100 00001100000011110011010, 
	 //	calculated = 0 01001011 00001100000011110011010
	 end else if (i == 51) begin //01
         floating_point1 = 32'b01110110111010011101111111101101; //2.37177133292e+33
	 floating_point2 = 32'b11110110100010011000010011101101; //-1.39461079055e+33
	 //Error: expected = 0 11101110 01110011011001001101101, 
	 //	calculated = 0 11101101 01110011011001001101101,
	 end else if (i == 52) begin //01
         floating_point1 = 32'b00100110010011000001111101001100; //7.08191329947e-16
	 floating_point2 = 32'b10100101111011111111100001001011; //-4.16281409359e-16
	 //Error: expected = 0 01001101 01000100000110110111000, 
	 //	calculated = 0 01001100 01000100000110110111000
	 end*/
	 /*else if (i == 49) begin 
         floating_point1 = 32'b11110001101100110100110011100011;   //-1.77570454712e+30
	 floating_point2 = 32'b11110010100110011110110011100101;   //-6.09761208551e+30
			  //fraction is 1101101001110011010110001
	 //Error: expected = 0 11100100  10110100011001101011000, 
	 //	calculated = 0 11100101 11011010001100110101100
	 end else if (i == 50) begin 
         floating_point1 = 32'b11110001001101111111001011100010;   //-9.10870145608e+29
	 floating_point2 = 32'b11110001100111000111000011100011;   //-1.54931626244e+30
			  //fraction is 1000000011101110111001000
	 //Error: expected = 0 11100010  00000001110111011100100, 
	 //	calculated = 0 11100011 10000000111011101110010,
	 end else if (i == 51) begin 
         floating_point1 = 32'b11001010000011100100010010010100;   //-2330917.0
	 floating_point2 = 32'b11001001011000011110010010010010;   //-925257.125
			  //fraction is 1010101110010110110111110
	 //Error: expected = 1 10010011  01010111001011011011111, 
	 //	calculated = 1 10010100 10101011100101101101111,
	 end else if (i == 52) begin 
         floating_point1 = 32'b10100110011000110110001001001100;  //-7.88896629161e-16
	 floating_point2 = 32'b10101001100000011001010001010011;  //-5.7544809575e-14
			  //fraction is 1111111110011011000111010
	 //Error: expected = 0 01010010  11111111001101100011100, 
	 //	calculated = 0 01010011 11111111100110110001110
	 end else if (i == 53) begin 
         floating_point1 = 32'b11100100100000100100110011001001;  //-1.92288774656e+22
	 floating_point2 = 32'b11100100110110000010000011001001;  //-3.18948731152e+22
			  //fraction is 1010101110101000000000000
	 //Error: expected = 0 11001000  01010111010100000000000, 
	 //	calculated = 0 11001001 10101011101010000000000,
	 end else if (i == 54) begin 
         floating_point1 = 32'b10110110001011011000010001101100;  //-2.58560885413e-06
	 floating_point2 = 32'b10110101110001011100000001101011;  //-1.47336447753e-06
			  //fraction is 1001010101001000011011010
	 //Error: expected = 1 01101011  00101010100100001101101, 
	 //	calculated = 1 01101100 10010101010010000110110
	 end else if (i == 55) begin 
 	 floating_point1 = 32'b11010001010010001000111010100010;  // -53836652544.0
	 floating_point2 = 32'b11010011000001011101100010100110;  // -5.74865408e+11
			  //fraction is 1111001010011111011110000
	 //Error: expected = 0 10100101  11100101001111101110111, 
	 //	calculated = 0 10100110 11110010100111110111100,
	 end else if (i == 56) begin
         floating_point1 = 32'b10101000101110110000110001010001;  //-2.07665119503e-14
	 floating_point2 = 32'b10101000111000011110111001010001;  //-2.50833713202e-14
			  //fraction is 0100110111000100000000000
	 //Error: expected = 0 01001111   00110111000100000000000, 
	 //	calculated = 0 01010001 01001101110001000000000


	 //Error: expected = 0 01001111   00110111000100000000000, 
	 //	calculated = 0 01010001 01001101110001000000000
	 end


	 /*else if (i == 49) begin
         floating_point1 = 32'b11100001001011001100111011000010; //-1.99e20
	 floating_point2 = 32'b01100100010101111110110111001000; //1.593e22
	 //Error: expected = 1 11001000 10110101010000100000011, 
	 //	calculated = 1 11001000 10100101000011101010010,
	 end else if (i == 50) begin
         floating_point1 = 32'b10000100011101111110010000001000; //-2.914e-36
	 floating_point2 = 32'b00001110010000010100010100011100; //2.38e-30
	 //Error: expected = 1 00011100 10000010100010100101011, 
	 //	calculated = 1 00011100 10000010100010100111011
	 end else if (i == 51) begin
         floating_point1 = 32'b11000110001110101001001010001100; //-11940.6367188
	 floating_point2 = 32'b01001000010010000111110110010000; //205302.25
	 //Error: expected = 1 10010000 10101000010011010111000, 
	 //	calculated = 1 10010000 10111111100111111100010,
	 end else if (i == 52) begin
         floating_point1 = 32'b10010101101010011010100000101011; //-6.85238786791e-26
	 floating_point2 = 32'b00011100100011010111111100111001; //9.36348359545e-22
	 //Error: expected = 1 00111001 00011011000000111011111, 
	 //	calculated = 1 00111001 00011011000010010000110
	 end else if (i == 53) begin
         floating_point1 = 32'b10101001011111110000000001010010; //-5.66216520827e-14
	 floating_point2 = 32'b00101100100001001000100101011001; //3.76691429785e-12
	 //Error: expected = 1 01011001 00001101000011101011001, 
	 //	calculated = 1 01011001 00010001000010101011010,
	 end*/	 /*end else if (i == 51) begin
         floating_point1 = 32'b11000000011001011011001000101101; //-3.589
	 floating_point2 = 32'b11000001000001101001001100001100; //-8.4109
	 //fraction is		        1001101001001101000000011
	 //Error: expected = 0 10000001  00110100100110100000001,
	 //	calculated = 0 10000010 10011010010011010000000
	 end else if (i == 52) begin
	 floating_point1 = 32'b11000010000011111000111101011100; //-45.89
	 floating_point2 = 32'b11000010101010000011011111001111; //-94.109
	 //fraction is 	 	        1100000011100000010000100
	 //Error: expected = 0 10000100  10000001110000001000010, 
	 //	calculated = 0 10000101 11000000111000000100001	*/

	 //If the sum overflows the position of the hidden bit, then the mantissa must be shifted one bit to the right and the exponent incremented



	 if(floating_point1[30:23] == 8'b11111111) 
	   floating_point1[30:23] = 8'b11111110;
	 if(floating_point2[30:23] == 8'b11111111) 
	   floating_point2[30:23] = 8'b11111110;

	 //convert from floating point to 2 real values
	 fp_convert(.val(floating_point1), .fp(fp1_real));
	 fp_convert(.val(floating_point2), .fp(fp2_real));

	 //performing real number arithemetic
	 //
	 if(funct7 == 7'b0100000) begin
	    result_real = fp1_real + fp2_real; //addition
	 end else if (funct7 == 7'b0000010) begin
	    result_real = fp1_real * fp2_real; //multiplication
         end else if (funct7 == 7'b0100100) begin
	    result_real = fp1_real - fp2_real; //subtraction
	 end
	 
	 else result_real = 'x;
	 
	 real_to_fp(.r(result_real), .fp(result_binary)); //convert the real number back to floating point
	 @(negedge clk);
	 @(negedge clk);
	 
	 fp_convert(.val(floating_point_out), .fp(fp_out_real));
	 #1;
	 assert((floating_point_out == result_binary) || (floating_point_out == result_binary + 1)) 
	   else begin
	      j = j + 1;
	      $error("expected = %b, calculated = %b, wrong case = %d, number = %d, fp1 is = %b, fp2 is = %b", result_binary, floating_point_out, i, j, floating_point1, floating_point2);
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
	 floating_point1 = 'x;
	 floating_point2 = 'x;
	 frm             = 'x;
	 funct7          = 'x;
	 result_real     = 'x;
	 fp1_real        = 'x;
	 fp2_real        = 'x;
	 fp_exp          = 'x;
	 fp_frac         = 'x;
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
   
initial begin
   nrst = 1;
   @(negedge clk);
   nrst = 0;
   @(negedge clk);
   nrst = 1;
   i = 0;
   
   /*while(i <= 56) begin
      random_check();
      i = i + 1;
      //break;
      end //*/
   while (1) begin
	i = i + 1;
	random_check();
  end //
end
   
endmodule // tb_FPU_top_level
