module fixed_point_datapath(clk, rst_n, decoded_instructions, vsew, vlen, vil, vl, vxrm, vm, rs1, rs2, vxsat, vs1, vs2, vd, debug_input, debug_output );

parameter LEN_CSR = 64;
input clk, rst_n;
input [4:0] decoded_instructions;
//All the inputs should come from vector control unit
//vlen should be compatible with rest of teh core
input [2:0] vsew;
input [7:0] vlen; 
input vil;
input [LEN_CSR - 1: 0] vl;

//fixed point specific inputs from register file (part of CSR)
//the support should be added in control unit 
input [1:0] vxrm;
output reg vxsat;
// spec 3.7 says about rounding 
// rounding results (v >> d)+r -- need to add support while runding operations
// to be don
//
input vm; //vm vector mask
//section 5.3.1 : vm=1 unmasked, vector resuts only visible if v0[i].LSB = 1
//section 7.1 talks about different field
//rs1 base address, rs2 stride : these are instruction field 5 bits each
//vd output register address base
//vs1 and vs2 are vector register group specified by the address 
input [4:0] rs1, rs2;
input [4:0] vs1, vs2, vd;
wire r;
reg [LEN_CSR - 1:0] reg_model [0:31];

//required to fill up this ..should be verified using other methods
initial begin //{
	for(integer i=1;i<=32; i=i+1) begin //{
	reg_model[i-1] = i+1;
	end //}
end //}

output [LEN_CSR - 1:0] debug_input, debug_output;

assign debug_input = reg_model[vs1];
assign debug_output = reg_model[vd];

assign sew = 8*2^(vsew);//vector spec 3.3.1
assign num_len = vlen/sew;

//if vil is set ignore vector operations

//vstart exception not supported
//


//Fixed point operations are coded below
// decode logic should be providing the states
//13.1 Vector fixed point Arithmetic instructions - single 
//everything is implemented for unsigned in the 1st version
localparam vsaddu_vv = 5'd1;
localparam vsaddu_vx = 5'd2;
localparam vsaddu_vi = 5'd3;
localparam vsadd_vv = 5'd4;
localparam vsadd_vx = 5'd5;
localparam vsadd_vi = 5'd6;
localparam vssubu_vv = 5'd7;
localparam vssubu_vx = 5'd8;
localparam vssub_vv = 5'd9;
localparam vssub_vx = 5'd10;
localparam vaaddu_vv = 5'd11;
localparam vaaddu_vx = 5'd12;
localparam vaadd_vv = 5'd13;
localparam vaadd_vx = 5'd14;
localparam vasubu_vv = 5'd15;
localparam vasubu_vx = 5'd16;
localparam vasub_vv = 5'd17;
localparam vasub_vx = 5'd18;
localparam vsmul_vv = 5'd19;
localparam vsmul_vx = 5'd20;
localparam vssrl_vv = 5'd21;
localparam vssrl_vx = 5'd22;
localparam vssrl_vi = 5'd23;
localparam vssra_vv = 5'd24;
localparam vssra_vx = 5'd25;
localparam vssra_vi = 5'd26;
localparam vnclipu_wv = 5'd27;
localparam vnclipu_wx = 5'd28;
localparam vnclipu_wi = 5'd29;
localparam vnclip_wv = 5'd30;
localparam vnclip_wx = 5'd31;
localparam vnclip_wi = 5'd32;

reg [LEN_CSR - 1 : 0] v1_signed, d1_signed;
reg [LEN_CSR - 1 : 0] v1_unsigned, d1_unsigned;
wire [LEN_CSR - 1 : 0] out1_unsigned, out1_signed;
wire [LEN_CSR - 1 : 0] r1_unsigned, r1_signed;

//Try to use generate blocks if more vectors are accomodated in a single lane
round_off_unsigned r1(clk, rst_n, vxrm, v1_unsigned, d1_unsigned, r1_unsigned, out1_unsigned); 
round_off_signed r2(clk, rst_n, vxrm, v1_signed, d1_signed, r1_signed, out1_signed); 
//round_off r2(clk, rst_n, vxrm, v2, d2, r2, out2); 
initial vxsat = 0;
// state change logic
// 2's compliment format, Dont have to take care of sign bits explicitly
always@(posedge clk, negedge rst_n) begin //{
	case (decoded_instructions)
		vsaddu_vv: begin //{
				if(vm == 0)begin //{
				 reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[vs1][LEN_CSR -1:32];
				 reg_model[vd][31:0] <= reg_model[vs2][31:0] + reg_model[vs1][31:0];
					if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{
						reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
						vxsat <= 1'b1;
					end //}
					if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
				end //}
			end //}
		vsaddu_vx: begin //{
			if(vm == 0) begin //{
			reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[rs1][LEN_CSR -1:0];	
			reg_model[vd][31:0] <= reg_model[vs2][31:0] + reg_model[rs1][LEN_CSR -1:0];
			if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
			if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
			end //}	
		end //}
		//bug fix after saturation add meaning
		vsaddu_vi: begin //{
                        if(vm == 0) begin //{
			reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[vs2+1][LEN_CSR -1:32]; 
			reg_model[vd][31:00] <= reg_model[vs2][31:00] + reg_model[vs2+1][31:00]; 
			if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                        if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                        end //} 
                end //}
		vsadd_vv: begin //{
			if(vm == 0)begin //{
				if(vm == 0)begin //{
                                 reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[vs1][LEN_CSR -1:32];
                                 reg_model[vd][31:0] <= reg_model[vs2][31:0] + reg_model[vs1][31:0];
                                        if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                        if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                end //}
				//if (reg_model[vs2][LEN_CSR -1] == reg_model[vs1][LEN_CSR -1]) begin //{
                                // reg_model[vd][LEN_CSR -2:32] <= reg_model[vs2][LEN_CSR -2:32] + reg_model[vs1][LEN_CSR -2:32];
                                //        if(reg_model[vd][LEN_CSR -1:32] > 31'h7FFFFFFF) begin //{
                                //                reg_model[vd][LEN_CSR -1:32] <= 31'h7FFFFFFF;
                                //                vxsat <= 1'b1;
                                //        end //}
                                //end //}
				//else if (reg_model[vs2][LEN_CSR -1] == 1'b1) begin //{
				//	reg_model[vd][LEN_CSR -2:32] <= reg_model[vs1][LEN_CSR -2:32] - reg_model[vs2][LEN_CSR -2:32];
                                //        if(reg_model[vd][LEN_CSR -1:32] > 31'h7FFFFFFF) begin //{
                                //                reg_model[vd][LEN_CSR -1:32] <= 31'h7FFFFFFF;
                                //                vxsat <= 1'b1;
                                //        end //}
				//end //}
				//if (reg_model[vs2][31] == reg_model[vs1][31]) begin //{
                                // reg_model[vd][30:0] <= reg_model[vs2][30:0] + reg_model[vs1][30:0];
				//		if(reg_model[vd][31:00] > 31'h7FFFFFFF) begin //{
                                //                reg_model[vd][31:00] <= 31'h7FFFFFFF;
                                //                vxsat <= 1'b1;
                                //        end //}
				//end //}
				end //}
                        end //}
                vsadd_vx: begin //{
			if(vm == 0) begin //{
                        reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[rs1][LEN_CSR -1:0];
                        reg_model[vd][31:0] <= reg_model[vs2][31:0] + reg_model[rs1][LEN_CSR -1:0];
                        if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                        if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                        end //}
                end //}

		vsadd_vi: begin //{
			if(vm == 0) begin //{
                        reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[vs2+1][LEN_CSR -1:32];
                        reg_model[vd][31:00] <= reg_model[vs2][31:00] + reg_model[vs2+1][31:00];
                        if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                        if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                        end //} 

                end //}
		vssubu_vv: begin //{
			 if(vm == 0)begin //{
                                 reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] - reg_model[vs1][LEN_CSR -1:32];
                                 reg_model[vd][31:0] <= reg_model[vs2][31:0] - reg_model[vs1][31:0];
                                        if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                        if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                end //}	
                        end //}
                vssubu_vx: begin //{
			 if(vm == 0)begin //{
                                 reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] - reg_model[rs1][LEN_CSR -1:0];
                                 reg_model[vd][31:0] <= reg_model[vs2][31:0] - reg_model[rs1][31:0];
                                        if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{ 
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                        if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                end //} 
                end //}
		vssub_vv: begin //{
			if(vm == 0)begin //{
                                 reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] - reg_model[vs1][LEN_CSR -1:32];
                                 reg_model[vd][31:0] <= reg_model[vs2][31:0] - reg_model[vs1][31:0];
                                        if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{ 
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                        if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                end //} 
                        end //}
                vssub_vx: begin //{
               		if(vm == 0)begin //{
                                 reg_model[vd][LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] - reg_model[rs1][LEN_CSR -1:0];
                                 reg_model[vd][31:0] <= reg_model[vs2][31:0] - reg_model[rs1][31:0];
                                        if(reg_model[vd][LEN_CSR -1:32] > 32'hFFFFFFFF) begin //{ 
                                                reg_model[vd][LEN_CSR -1:32] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                        if(reg_model[vd][31:00] > 32'hFFFFFFFF) begin //{
                                                reg_model[vd][31:00] <= 32'hFFFFFFFF;
                                                vxsat <= 1'b1;
                                        end //}
                                end //} 	
		end //}
		vaaddu_vv: begin //{
                                if(vm == 0)begin //{
                                 v1_unsigned[LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[vs1][LEN_CSR -1:32];
                                 v1_unsigned[31:0] <= reg_model[vs2][31:0] + reg_model[vs1][31:0];
				 d1_unsigned <= 1;
				 reg_model[vd] <= out1_unsigned;
				 //reg_model[vd][31:0] <= out1_unsigned[31:0];
                                end //}
                        end //}
                vaaddu_vx: begin //{
                		if(vm == 0)begin //{
                                 v1_unsigned[LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[rs1];
                                 v1_unsigned[31:0] <= reg_model[vs2][31:0] + reg_model[rs1];
                                 d1_unsigned<= 1;
                                 reg_model[vd] <= out1_unsigned;
                                 //reg_model[vd][31:0] <= out1_unsigned[31:0];
                                end //}
		end //}

                vaadd_vv: begin //{
                		if(vm == 0)begin //{
                                 v1_signed[LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[vs1][LEN_CSR -1:32];
                                 v1_signed[31:0] <= reg_model[vs2][31:0] + reg_model[vs1][31:0];
                                 d1_signed<= 1;
                                 reg_model[vd] <= out1_signed;
                                 //reg_model[vd][31:0] <= out1_signed[31:0];
                                end //}        
		end //}
                vaadd_vx: begin //{
                		if(vm == 0)begin //{
                                 v1_signed[LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] + reg_model[rs1];
                                 v1_signed[31:0] <= reg_model[vs2][31:0] + reg_model[rs1];
                                 d1_signed <= 1;
                                 reg_model[vd] <= out1_signed;
                                 //reg_model[vd][31:0] <= out1_signed[31:0];
                                end //}
		end //}
		vasubu_vv: begin //{
                       		if(vm == 0)begin //{
                                 v1_unsigned[LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] - reg_model[vs1][LEN_CSR -1:32];
                                 v1_unsigned[31:0] <= reg_model[vs2][31:0] - reg_model[vs1][31:0];
                                 d1_unsigned <= 1;
                                 reg_model[vd] <= out1_unsigned;
                                 //reg_model[vd][31:0] <= out1_unsigned[31:0];
                                end //}
			end //}
                vasubu_vx: begin //{
				if(vm == 0)begin //{
                                 v1_unsigned[LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] - reg_model[rs1];
                                 v1_unsigned[31:0] <= reg_model[vs2][31:0] - reg_model[rs1];
                                 d1_unsigned<= 1;
                                 reg_model[vd] <= out1_unsigned;
                                 //reg_model[vd][31:0] <= out1_unsigned[31:0];
                                end //}
                end //}

		vasub_vv: begin //{
		                if(vm == 0)begin //{
                                 v1_signed[LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] - reg_model[vs1][LEN_CSR -1:32];
                                 v1_signed[31:0] <= reg_model[vs2][31:0] - reg_model[vs1][31:0];
                                 d1_signed<= 1;
                                 reg_model[vd] <= out1_signed;
                                 //reg_model[vd][31:0] <= out1_signed[31:0];
                                end //}
        
		end //}
                vasub_vx: begin //{
                		if(vm == 0)begin //{
                                 v1_signed[LEN_CSR -1:32] <= reg_model[vs2][LEN_CSR -1:32] - reg_model[rs1];
                                 v1_signed[31:0] <= reg_model[vs2][31:0] - reg_model[rs1];
                                 d1_signed <= 1;
                                 reg_model[vd] <= out1_signed;
                                 //reg_model[vd][31:0] <= out1_signed[31:0];
                                end //}
		end //}
		vsmul_vv: begin //{
                                if(vm == 0) reg_model[vd][LEN_CSR -1:0] <= reg_model[vs2][LEN_CSR -1:0] * reg_model[vs1][LEN_CSR -1:0]; //multiplication as of now supports 16 bit individual operation
                        //vxsat <= 1'b1;
                        end //}
                vsmul_vx: begin //{
                        if(vm == 0) reg_model[vd][LEN_CSR -1:0] <= reg_model[vs2][LEN_CSR -1:0] * reg_model[rs1][LEN_CSR -1:0]; // multiplication as of now supports 16 bit individual componnt operations
                        //vxsat <= 1'b1;
                end //}

                vssrl_vv: begin //{	
				if(vm == 0) begin //{
					v1_unsigned <= reg_model[vs2];
					d1_unsigned <= reg_model[vs1];
					reg_model[vd] <= out1_unsigned;
				end //}
		end //}
                vssrl_vx: begin //{
                		if(vm == 0) begin //{
					v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= {reg_model[rs1][31:0],reg_model[rs1][31:0]};
                                        reg_model[vd] <= out1_unsigned;
				end //}
		end //}

                vssrl_vi: begin //{
                		if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= {reg_model[vs2+1]};
                                        reg_model[vd] <= out1_unsigned;
                                end //}
		end //}
                vssra_vv: begin //{
				if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= reg_model[vs1];
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                end //}
		vssra_vx: begin //{
				if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= {reg_model[rs1][31:0],reg_model[rs1][31:0]};
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                        end //}
                vssra_vi: begin //{
				if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= {reg_model[vs2+1]};
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                end //}

		vnclipu_wv: begin //{     
                                if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= reg_model[vs1];
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                end //}
                vnclipu_wx: begin //{
                                if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= {reg_model[rs1][31:0],reg_model[rs1][31:0]};
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                end //}

                vnclipu_wi: begin //{
                                if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= {reg_model[vs2+1]};
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                end //}
		vnclip_wv: begin //{     
                                if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= reg_model[vs1];
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                end //}
                vnclip_wx: begin //{
                                if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= {reg_model[rs1][31:0],reg_model[rs1][31:0]};
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                end //}

                vnclip_wi: begin //{
                                if(vm == 0) begin //{
                                        v1_unsigned <= reg_model[vs2];
                                        d1_unsigned <= {reg_model[vs2+1]};
                                        reg_model[vd] <= out1_unsigned;
                                end //}
                end //}
endcase
end //}
// All the states added
// state change logic
// module for rounding operations
endmodule
