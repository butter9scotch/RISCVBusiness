//By            : Zhengsen Fu, Xinlue Liu
//Description   : this interface handles all the internal communication between register file and FPU
//Last Updated  : 7/14/20


`ifndef REGISTER_FPU_IF_SVH
`define REGISTER_FPU_IF_SVH
interface register_FPU_if(input logic n_rst, clk);
  logic [31:0] f_w_data; //select between data from the memory or FPU_out
  logic [31:0] f_rs1_data; //first operand outputted from register file
  logic [31:0] f_rs2_data; //second operand outputted from register file
  logic [31:0] FPU_out; //calculated result from FPU
  logic f_wen; //write enable. Enable register file to written by FPU TODO: implementation of this signal

  
  logic [2:0] frm; //rounding method.


  // logic f_NV; //invalid operation flag
  // logic f_DZ; //divided by zero flag
  // logic f_OF; //overflow flag
  // logic f_UF; //underflow flag
  // logic f_NX; //inexact result flag
  logic [4:0] flags; //a combination of NV, DZ, OF, UF, NX


  logic f_ready; //asserted when calculation finished by FPU
  logic [7:0] funct_7; //operation selection of FPU

  modport fp ( //to FPU
  input f_rs1_data, f_rs2_data, frm, funct_7, 
  output FPU_out, flags
  );

  modport rf ( //to register file
  input f_w_data, f_rs1, f_rs2, f_rd, f_wen, flags
  output f_rs1_data, f_rs2_data, f_frm_out, f_flags, frm
  );

  modport cc(
    input f_rs1_data, f_rs2_data, funct_7, frm,
    output f_ready
  );

  // modport cu (
  //   output f_rs1, f_rs2, f_rd
  // );
  
endinterface //FPU_if


`endif
