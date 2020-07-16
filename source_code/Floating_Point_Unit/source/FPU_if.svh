//By            : Zhengsen Fu, Xinlue Liu
//Last Updated  : 7/14/20

`ifndef FPU_IF_SVH
`define FPU_IF_SVH
interface FPU_if(input logic clk);
  //signals to and out of FPU and FPU register file
  logic f_LW; //load or write. Load content from outside or write from FPU to register file
  logic f_wen; //write enable. Enable register file to written by FPU

  logic [4:0] f_rs1; //register selection 1. Select operand 1 from a register
  logic [4:0] f_rs2; //register selection 2. Select operand 2 from a register
  logic [4:0] f_rd; //register destination. Select which register to be written

  logic [2:0] frm; //rounding method.
  
  logic [4:0] f_flags; //a combination of NV, DZ, OF, UF, NX
  logic [7:0] f_funct_7; //operation selection of FPU
  logic [2:0] f_frm_out; //frm outputed by register file


  modport fp ( //to FPU_all
  input f_rd, f_rs1, f_rs2, frm, f_LW, f_wen, 
  output FPU_out, f_flags, frm_out
  );
  
endinterface //FPU_if


`endif
