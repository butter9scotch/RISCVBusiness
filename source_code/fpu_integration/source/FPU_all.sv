
//created by Sean Hsu
//Modified by Xinlue Liu, Zhengsen Fu
//Last Updated  : 7/21/20

`include "FPU_if.vh"
`include "f_register_file_if.vh"

module FPU_all(FPU_if.fp fpu_if);

  /*register_FPU_if frf_if(
    .n_rst(fpu_if.n_rst), 
    .clk(fpu_if.clk),
    .f_rs1(fpu_if.f_rs1),
    .f_rs2(fpu_if.f_rs2),
    .f_rd(fpu_if.f_rd),
    .f_LW(fpu_if.f_LW),
    .f_SW(fpu_if.f_SW),
    .f_flags(fpu_if.f_flags), //??
    .f_frm_out(fpu_if.f_frm_out),
    .f_frm_in(fpu_if.f_frm_in),
    .funct_7(fpu_if.f_funct_7)
  ); */
  //FPU register file interface
  f_register_file_if frf_if();

//fpu load. 2 to 1 multiplexer choose between dload_ext[31:0] and FPU_out[31:0] from fpu
assign frf_if.f_w_data = fpu_if.f_LW ? fpu_if.dload_ext : frf_if.FPU_out;
assign fpu_if.FPU_all_out = fpu_if.f_SW ? frf_if.f_rs2_data : '0; 
assign frf_if.f_frm_in = fpu_if.f_frm_in;
assign frf_if.clk = fpu_if.clk;
assign frf_if.n_rst = fpu_if.n_rst;
assign fpu_if.f_flags = frf_if.f_flags;
assign frf_if.f_wen = fpu_if.f_wen;
assign frf_if.f_rs1 = fpu_if.f_rs1;
assign frf_if.f_rs2 = fpu_if.f_rs2;
assign frf_if.f_rd = fpu_if.f_rd;
assign frf_if.f_LW = fpu_if.f_LW;
assign frf_if.f_SW = fpu_if.f_SW;
    

clock_counter cc(frf_if.cc);

FPU_top_level FPU(
.clk(frf_if.clk), 
.nrst(frf_if.n_rst),
.floating_point1(frf_if.f_rs1_data),
.floating_point2(frf_if.f_rs2_data),
.frm(frf_if.frm),
.funct7(frf_if.funct_7),
.floating_point_out(frf_if.FPU_out),
.flags(frf_if.flags)
);

f_register_file f_rf(frf_if.rf);

endmodule

