//By            : Zhengsen Fu, Xinlue Liu
//Description   : Interface connect top-level to FPU
//Last Updated  : 7/14/20

`ifndef FPU_IF_SVH
`define FPU_IF_SVH
interface FPU_if(input logic n_rst, clk);
  //signals to and out of FPU and FPU register file
  logic f_LW; //load. Load from memory to register
  logic f_SW; //save. Save from rs2 to memory 
  logic f_wen; //write enable. Enable register file to written by FPU TODO: implementation of this signal

  logic [4:0] f_rs1; //register selection 1. Select operand 1 from a register
  logic [4:0] f_rs2; //register selection 2. Select operand 2 from a register
  logic [4:0] f_rd; //register destination. Select which register to be written

  logic [2:0] frm_in; //input rounding method.
  logic [4:0] f_flags; //a combination of NV, DZ, OF, UF, NX
  logic [7:0] f_funct_7; //operation selection of FPU
  logic [2:0] f_frm_out; //frm outputed by register file TODO: confusing
  
  logic [31:0] dload_ext; //TODO: confirm the identifier
  logic [31:0] FPU_all_out; //output when f_SW is asserted

  logic f_ready; //asserted when calculation finished by FPU

  modport fp ( //to FPU_all
  input f_rd, f_rs1, f_rs2, frm, f_LW, f_SW, f_wen, f_funct_7, dload_ext,
  output FPU_all_out, f_flags, f_frm_out, f_ready
  );
  
endinterface //FPU_if


`endif
