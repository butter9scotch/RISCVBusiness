module sign_determine
  (
   input 	 temp_sign,
   input [31:0]  temp_floating_point_out,
   input 	 cmp_out,
   output [31:0] floating_point_out
   );
   
   logic [31:0] temp_result;
   
   assign temp_result [30:0] = temp_floating_point_out[30:0];
   
   always_comb begin
      if (cmp_out == 1'b1) begin
	 temp_result[31] = ~temp_sign;
      end else begin
	 temp_result[31] = temp_sign;
      end
   end

   assign floating_point_out[31:0] = temp_result[31:0];
   
endmodule // sign_determine

