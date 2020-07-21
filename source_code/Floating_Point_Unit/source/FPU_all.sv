
//created by Sean Hsu
//Modified by Xinlue Liu, Zhengsen Fu
//Last Updated  : 7/21/20

`include "FPU_if.svh"
`include "register_FPU_if.svh"

module FPU_all(FPU_if.fp fpu_if);

 register_FPU_if frf_if(.n_rst(fpu_if.n_rst), .clk(fpu_if.clk)); //FPU register file interface

//fpu load. 2 to 1 multiplexer choose between dload_ext[31:0] and FPU_out[31:0] from fpu
assign frf_if.f_w_data = fpu_if.f_LW ? frf_if.FPU_out : fpu_if.dload_ext;
assign fpu_if.FPU_all_out = fpu_if.f_SW ? frf_if.f_rs2_data : '0; 
assign fpu_if.f_flags = frf_if.flags;
assign frf_if.f_wen = fpu_if.f_wen;

clock_counter cc(frf_if.cc);

FPU_top_level FPU(
.clk(clk), 
.nrst(nrst),
.floating_point1(frf_if.f_rs1_data),
.floating_point2(frf_if.f_rs2_data),
.frm(frf_if.frm),
.funct7(frf_if.funct_7),
.floating_point_out(frf_if.FPU_out),
.flags(frf_if.flags),
);

f_register_file f_rf(frf_if.rf);

endmodule
