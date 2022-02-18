`timescale 1ns/10ps
module tb_rv32v_multiplier ();
	parameter BIT_WIDTH = 32;
	parameter CLOCK_PERIOD = 10ns;
	logic tb_CLK, tb_nRST;
	logic tb_start, tb_finished;
	logic [(BIT_WIDTH-1):0] tb_multiplicand;
	logic [(BIT_WIDTH-1):0] tb_multiplier;
	logic [(2*BIT_WIDTH-1):0] tb_product;
	logic [1:0] tb_is_signed;
	logic [(2*BIT_WIDTH+5):0] tb_expected_out;
	integer tb_test_case_num;
	typedef struct {
		string test_name;
		logic [(BIT_WIDTH-1):0] test_multiplicand;
		logic [(BIT_WIDTH-1):0] test_multiplier;
		logic [1:0] test_is_signed;
	} testvector;
	testvector tb_test_case [];
	
	rv32v_multiplier DUT (.CLK(tb_CLK), .nRST(tb_nRST), .multiplicand(tb_multiplicand), .multiplier(tb_multiplier), .is_signed(tb_is_signed), .start(tb_start), .finished(tb_finished), .product(tb_product));

	always begin
		tb_CLK=0;
		#(CLOCK_PERIOD/2.0);
		tb_CLK=1;
		#(CLOCK_PERIOD/2.0);
	end

        task delay;
          input integer i;
        begin
          for (int j = 0; j < i; j++) begin
            @(posedge tb_CLK);
          end
        end
        endtask 

	task reset_dut();
		@(negedge tb_CLK);
		tb_nRST = 0;
		@(posedge tb_CLK);
		@(posedge tb_CLK);
		#(CLOCK_PERIOD/4.0);
		tb_nRST = 1;
	endtask

        task start_op;
          input logic [31:0] x;
          input logic [31:0] y;
          input logic [1:0] s;
        begin
          @(posedge tb_CLK);
          tb_multiplicand = x;
          tb_multiplier = y;
          tb_is_signed = s;
          tb_start = 1;
        end
        endtask

	initial begin
		tb_test_case = new[11];
		// Random multiplier and multiplicand
		tb_test_case[0].test_name = "Random multiplier and multiplicand";
		tb_test_case[0].test_multiplicand = 32'd183978223;
		tb_test_case[0].test_multiplier = 32'd490177653;
		tb_test_case[0].test_is_signed = 2'b00;
		// Multiplier with concatenation of all possible 3-bits values in bitpair recoding
		tb_test_case[1].test_name = "Multiplier with concatenation of all possible 3-bits values in bitpair recoding";
		tb_test_case[1].test_multiplicand = 32'd478013;
		tb_test_case[1].test_multiplier = {{10'd0}, {22'b1110100110011100100100}};
		tb_test_case[1].test_is_signed = 2'b00;
		// Unsigned multiplicand and unsigned multiplier
		tb_test_case[2].test_name = "Unsigned multiplicand and unsigned multiplier";	
		tb_test_case[2].test_multiplicand = '1 >> 1;
		tb_test_case[2].test_multiplier = '1 >> 1;
		tb_test_case[2].test_is_signed = 2'b00;
		// Signed multiplicand and unsigned multiplier
		tb_test_case[3].test_name = "Signed multiplicand and unsigned multiplier";
		tb_test_case[3].test_multiplicand = -28752;
		tb_test_case[3].test_multiplier = 32'd839011;
		tb_test_case[3].test_is_signed = 2'b10;
		// Unsigned multiplicand and signed multiplier	
		tb_test_case[4].test_name = "Unsigned multiplicand and signed multiplier";
		tb_test_case[4].test_multiplicand = 32'd7212691;
		tb_test_case[4].test_multiplier = -43892;
		tb_test_case[4].test_is_signed = 2'b01;
		// Signed multiplicand and signed multiplier
		tb_test_case[5].test_name = "Signed multiplicand and signed multiplier";
		tb_test_case[5].test_multiplicand = -7268;
		tb_test_case[5].test_multiplier = -897192;
		tb_test_case[5].test_is_signed = 2'b11;
		// MSB is 1 but unsigned - Both	
		tb_test_case[6].test_name = "MSB is 1 but unsigned - Both";
		tb_test_case[6].test_multiplicand = '1;
		tb_test_case[6].test_multiplier = '1;
		tb_test_case[6].test_is_signed = 2'b00;	
		// MSB is 1 but unsigned - Multiplicand	
		tb_test_case[7].test_name = "MSB is 1 but unsigned - Multiplicand";
		tb_test_case[7].test_multiplicand = '1;
		tb_test_case[7].test_multiplier = 32'd59;
		tb_test_case[7].test_is_signed = 2'b00;	
		// MSB is 1 but unsigned - Multiplier	
		tb_test_case[8].test_name = "MSB is 1 but unsigned - Multiplier";
		tb_test_case[8].test_multiplicand = 32'd38013;
		tb_test_case[8].test_multiplier = '1;
		tb_test_case[8].test_is_signed = 2'b00;	
		//expected result: 0x80004000	
		tb_test_case[9].test_name = "ERROR - Signed Unsigned";
		tb_test_case[9].test_multiplicand = 32'hffff_8000;
		tb_test_case[9].test_multiplier = 32'h8000_0000;
		tb_test_case[9].test_is_signed = 2'b01;	
		//expected result: 0x80004000	
		tb_test_case[10].test_name = "ERROR - Unsigned Signed";
		tb_test_case[10].test_multiplicand = 32'h8000_0000;
		tb_test_case[10].test_multiplier = 32'hffff_8000;
		tb_test_case[10].test_is_signed = 2'b10;	end

	initial begin
		tb_multiplier = '0;
		tb_multiplicand = '0;
		tb_is_signed = '0;
		tb_start = 0;
		tb_nRST = 1;	
                reset_dut();	
                /*start_op(1,1,0);
                start_op(2,2,0);
                start_op(3,3,0);
                start_op(4,4,0);
                start_op(5,5,0); */
		for (tb_test_case_num = 0; tb_test_case_num < tb_test_case.size(); tb_test_case_num ++) begin
			$display("TEST CASE %d - %s", tb_test_case_num, tb_test_case[tb_test_case_num].test_name);
                        start_op(tb_test_case[tb_test_case_num].test_multiplicand, tb_test_case[tb_test_case_num].test_multiplier, tb_test_case[tb_test_case_num].test_is_signed);
		end 
                @(posedge tb_CLK);
                tb_start = 0;
                delay(10);
		$finish;
	end
	
endmodule
