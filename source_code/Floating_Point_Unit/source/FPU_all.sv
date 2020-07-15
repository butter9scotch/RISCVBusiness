`include "FPU_all_if.vh"
`include "f_register_file_if.vh"

module FPU_all
(
 input 	       clk,
 input 	       nrst,
 //input [2:0] f_start, //signal to start,where 101 signals start, and others signal show not starting
 FPU_all_if.fp fpif  //  input f_rd, f_rs1, f_rs2, frm, f_LW, f_wen, output FPU_out, f_flags, frm_out
 );

logic [31:0] f_rs1_data, f_rs2_data; //fp1 and fp2

logic [7:0] f_funct_7; //is it necessary???

FPU_top_level FPU(
.clk(clk), 
.nrst(nrst),
.floating_point1(f_rs1_data), //f_rs1
.floating_point2(f_rs2_data), //f_rs2
.frm(fpif.frm),
.funct7(f_funct_7),
.floating_point_out(fpif.FPU_out),
.flags(fpif.flags),
.f_ready(fready)
);


/*    input f_w_data, f_rs1, f_rs2, f_rd, f_wen, f_NV, f_DZ, f_OF, f_UF, f_NX, f_frm_in, 
    output f_rs1_data, f_rs2_data, f_frm_out, f_flags*/
f_register_file(
.clk(clk),
.nrst(nrst),
.f_w_data(fpif.FPU_out),		//todo
.f_rs1(fpif.f_rs1), 
.f_rs2(fpif.f_rs2),
.f_rd(fpif.f_rd),
.f_wen(fpif.f_wen),
.f_NV(fpif.flags[4]),
.f_DZ(fpif.flags[3]),  
.f_OF(fpif.flags[2]),
.f_UF(fpif.flags[1]),
.f_NX(fpif.flags[0]),
.f_frm_in(fpif.frm),
.f_frm_out(fpif.frm_out),
.f_rs1_data(fpif.f_rs1_data),
.f_rs2_data(fpif.f_rs2_data),
.f_flags(fpif.f_flags)
);

endmodule
