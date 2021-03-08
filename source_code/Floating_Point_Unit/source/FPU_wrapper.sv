//By            :  Owen Prince
//Last Updated  : 3/8/21
//
//Module Summary:
//  wrapper module to use interface with the FPU_top_level module 
//

module FPU_wrapper
(
  input 	       clk,
  input 	       nrst,
	rv32f_if.fpu   fpu_if
);

	FPU_top_level fpu(.clk(clk),
										.nrst(nrst),
										.floating_point1
										.floating_point2
										.frm(fpu_if.frm),
										.funct7(fpu_if.funct7),
										.floating_point_out(fpu_if.floating_point_out),
										.flags(fpu_if.flags)
									 );


 endmodule 
