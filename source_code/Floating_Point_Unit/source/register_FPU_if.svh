//By            : Zhengsen Fu, Xinlue Liu
//Description: this interface handles all the internal communication between register file and FPU
//Last Updated  : 7/14/20


`ifndef REGISTER_FPU_IF_SVH
`define REGISTER_FPU_IF_SVH
interface register_FPU_if(input logic clk);
  logic [31:0] f_w_data; //FPU_out: calculated result from FPU
  logic [31:0] f_rs1_data; //first operand outputted from register file
  logic [31:0] f_rs2_data; //second operand outputted from register file

  logic f_NV; //invalid operation flag
  logic f_DZ; //divided by zero flag
  logic f_OF; //overflow flag
  logic f_UF; //underflow flag
  logic f_NX; //inexact result flag



  modport fp ( //to FPU
  input f_rd, f_rs1, f_rs2, frm, f_LW, f_wen, 
  output FPU_out, f_flags, frm_out
  );

  modport rf ( //to register file
  input f_w_data, f_rs1, f_rs2, f_rd, f_wen, f_NV, f_DZ, f_OF, f_UF, f_NX, f_frm_in, 
  output f_rs1_data, f_rs2_data, f_frm_out, f_flags
  );

  // modport cu (
  //   output f_rs1, f_rs2, f_rd
  // );
  
endinterface //FPU_if


`endif
