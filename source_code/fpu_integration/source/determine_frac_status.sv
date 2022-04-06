module determine_frac_status
(
   input [22:0]  fp1_frac1,
   input [22:0]  fp2_frac2,
   output reg frac_same
);

wire [23:0] temp_fp1_frac1 = {1'b0, fp1_frac1};
wire [23:0] temp_fp2_frac2 = {1'b0, fp2_frac2};
reg [23:0] diff_frac1_frac2;
reg diff_determine;

always_comb begin
	diff_frac1_frac2 = temp_fp1_frac1 - temp_fp2_frac2;
	case(diff_frac1_frac2[23])
		1'b0: diff_determine = 1'b0;
		1'b1: diff_determine = 1'b1;
	endcase
end
always_comb begin
	frac_same = 0;
	if (diff_determine == 1'b1)
		frac_same = 1'b1;
end

endmodule
