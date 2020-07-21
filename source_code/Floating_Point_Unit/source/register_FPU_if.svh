//By            : Zhengsen Fu, Xinlue Liu
//Description   : this interface handles all the internal communication between register file and FPU
//Last Updated  : 7/21/20


`ifndef REGISTER_FPU_IF_SVH
`define REGISTER_FPU_IF_SVH
interface register_FPU_if(
    input logic n_rst, clk,
    input logic [4:0] f_rs1, //register selection 1. Select operand 1 from a register
    input logic [4:0] f_rs2, //register selection 2. Select operand 2 from a register
    input logic [4:0] f_rd, //register destination. Select which register to be written
    input logic f_LW, //load. Load from memory to register
    input logic f_SW, //save. Save from rs2 to memory 
    input logic [4:0] f_flags, //a combination of NV, DZ, OF, UF, NX
    input logic [2:0] f_frm_out
  );
  logic [31:0] f_w_data; //select between data from the memory or FPU_out
  logic [31:0] f_rs1_data; //first operand outputted from register file
  logic [31:0] f_rs2_data; //second operand outputted from register file
  logic [31:0] FPU_out; //calculated result from FPU

  logic [2:0] frm; //rounding method.

  logic [4:0] flags; //a combination of NV, DZ, OF, UF, NX

  logic f_ready; //asserted when calculation finished by FPU
  logic [7:0] funct_7; //operation selection of FPU

  // signals from outside
  // logic [4:0] f_rs1; //register selection 1. Select operand 1 from a register
  // logic [4:0] f_rs2; //register selection 2. Select operand 2 from a register
  // logic [4:0] f_rd; //register destination. Select which register to be written
  // logic f_LW; //load. Load from memory to register
  // logic f_SW; //save. Save from rs2 to memory 
  // logic [4:0] f_flags; //a combination of NV, DZ, OF, UF, NX



  modport fp ( //to FPU
  input f_rs1_data, f_rs2_data, frm, funct_7, 
  output FPU_out, flags
  );

  modport rf ( //to register file
  input f_w_data, f_rs1, f_rs2, f_rd, flags, f_LW, f_SW, f_ready,
  output f_rs1_data, f_rs2_data, f_frm_out, f_flags, frm
  );

  modport cc( //to clock counter
    input f_rs1_data, f_rs2_data, funct_7, frm,
    output f_ready
  );

  // modport cu (
  //   output f_rs1, f_rs2, f_rd
  // );
  
endinterface //FPU_if


`endif
