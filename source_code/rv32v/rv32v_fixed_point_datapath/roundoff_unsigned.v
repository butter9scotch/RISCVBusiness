module round_off_unsigned(clk, rst_n, vxrm, v, d, r, out);
parameter LEN_CSR = 64;
parameter LEN_VECTOR = 32; //should come from sew field

input clk, rst_n;
input [1:0] vxrm;
//input vxrm_encoding_enable; 

input [LEN_CSR - 1: 0] v,d;
output reg [LEN_CSR - 1: 0] out;

output reg[LEN_CSR -1: 0] r;

always@(d) begin //{
        //r <= (vxrm == 2'b00)? v[d-1]: (vxrm == 2'b01) ? (v[d-1] & (!(v[d-2 : 0]== 0) | v[d])) : (vxrm == 2'b10) ? 0: (!v[d] & (v[d-1 : 0] != 0)); //this is algorithmically correct. We need to fix it in verilog
        r <= (vxrm == 2'b00)? v[d-1]: (vxrm == 2'b10) ? 0: v[d-1]; //this is algorithmically correct. We need to fix it in verilog
        //r <= (vxrm == 2'b00)? v[d-1]: (vxrm == 2'b01) ? (v[d-1] & ((v[d-2 : 0]!= 0) | v[d])) : (vxrm == 2'b10) ? 0: (vxrm == 2'b11) ? (!v[d] & (v[d-1 : 0] != 0));
end //} 

always@(posedge clk, negedge rst_n) begin //{

	if(rst_n == 0 ) begin //{
		out <= 0;
	end //}
	else begin //{
		out[63:32] <= (v[63:32] >> d) + r; 
		out[31:00] <= (v[31:00] >> d) + r; 
	end //}

end //}
 
 
endmodule
