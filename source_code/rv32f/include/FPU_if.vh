//By            : Zhengsen Fu, Xinlue Liu
//Description   : Interface connect top-level to FPU
//Last Updated  : 7/21/20

`ifndef FPU_IF_VH
`define FPU_IF_VH
`include "rv32i_types_pkg.vh"
import rv32i_types_pkg::*;
interface FPU_if(input logic n_rst, clk);
  //signals to and out of FPU and FPU register file
  //logic f_LW; //load. Load from memory to register
  //logic f_SW; //save. Save from rs2 to memory 
  //logic f_wen; //write enable. Enable register file to written by FPU TODO: implementation of this signal

  word_t port_a, port_b; //input operands to the fpu

  logic [2:0] f_frm_in; //input rounding method.
  logic [4:0] f_flags; //a combination of NV, DZ, OF, UF, NX
  logic [7:0] f_funct_7; //operation selection of FPU
  //logic [2:0] f_frm_out; //frm outputed by register file TODO: confusing
  
  logic [31:0] fpu_out; //output when f_SW is asserted

  logic f_ready; //asserted when calculation finished by FPU

  int transaction_number; //waveform debug purpose

  modport fp ( //to FPU_top_level
  input n_rst, clk, port_a, port_b, f_frm_in, f_funct_7,
  output fpu_out, f_flags //f_frm_out
  );
  
  modport cc ( //to clock counter
  input n_rst, clk, port_a, port_b, f_frm_in, f_funct_7,
  output f_ready //f_frm_out
  );

  modport tb (
    input fpu_out, f_flags, f_ready,
    output port_a, port_b, f_frm_in, f_funct_7 
  );
endinterface //FPU_if


`endif
