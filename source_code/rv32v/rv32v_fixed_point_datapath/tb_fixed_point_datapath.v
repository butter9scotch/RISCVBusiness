module tb_fixed_point_datapath();

parameter LEN_CSR = 64;
reg clk = 0;
reg rst_n;
reg [5:0] decoded_instructions;
//All the regs should come from vector control unit
//vlen should be compatible with rest of the core
reg [2:0] vsew;
reg [7:0] vlen; 
reg vil;
reg [LEN_CSR - 1: 0] vl;
reg [4:0] vs1, vs2, vd;
//fixed point specific inputs from register file (part of CSR)
//the support should be added in control unit 
reg [1:0] vxrm;
wire vxsat;
//
reg vm; //vm vector mask
reg [4:0] rs1, rs2;
wire r;
//reg [LEN_CSR - 1:0] reg_model [0:31]


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

reg [LEN_CSR - 1 : 0] v1, d1, r1;
wire [LEN_CSR -1 :0] debug_input, debug_output;

fixed_point_datapath fp(clk, rst_n, decoded_instructions, vsew, vlen, vil, vl, vxrm, vm, rs1, rs2, vxsat, vs1, vs2, vd, debug_input, debug_output );

always #5 clk = ~clk;

initial begin //{
	$dumpfile("fixed_point_datapath_waveform.vcd");
	$dumpvars(0, fp);
end //}

//test logic below
initial begin //{
	rst_n = 0;
	decoded_instructions = $urandom(); 
	//decoded_instructions = 19; 
	vsew = 	2;
	// check the 3 following values. Normally they come from vector CSRs 
	vl = 0;		
	vil = 0;
	vlen = 2;
	vxrm = $urandom; 
	vm = $random;
	rs1 = 14;
	rs2 = 15;
	vd = 17;
	vs1 = 18;
	vs2 = 19;	
	#100 rst_n = 1;
	#5000 $finish;	
end //}

// state change logic
// 2's compliment format, Dont have to take care of sign bits explicitly

// All the states added
// state change logic
// module for rounding operations
//

endmodule
