`ifndef FPU_ALL_IF_VH
`define FPU_ALL_IF_VH

interface FPU_all_if; //rename

logic [31:0] f_rd, f_rs1, f_rs2, FPU_out; //typo f_rd, f_rs1, f_rs2
logic f_LW, f_wen; //f_lw chooses between FPU_out or integer from ALU, f_wen is write enable
logic [2:0] frm, frm_out;
logic [4:0] f_flags;
logic f_ready;

modport fp(
  input f_rd, f_rs1, f_rs2, frm, f_LW, f_wen, 
  output FPU_out, f_flags, frm_out, f_ready
);

endinterface
`endif
