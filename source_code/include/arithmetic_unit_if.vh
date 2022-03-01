`ifndef ARITHMETIC_UNIT_IF_VH
`define ARITHMETIC_UNIT_IF_VH

interface arithmetic_unit_if(input rv32i_types_pkg::arith_control_signals_t control_sigs);

  // import alu_types_pkg::*;
  import rv32i_types_pkg::word_t;
  import rv32i_types_pkg::aluop_t;
  import rv32i_types_pkg::w_src_t;

  logic wen;
  aluop_t aluop;
  word_t port_a;
  word_t port_b;
  word_t reg_file_wdata;
  word_t csr_rdata;
  word_t pc;
  w_src_t w_src;
  word_t wdata_au;
  logic wen_au;
  word_t imm_UJ_ext;
  word_t imm_I_ext;
  logic [4:0] reg_rd_au;
  logic busy_au;
  logic j_sel;

  always_comb begin : CONNECTIONS
    wen_au = control_sigs.wen;
    aluop = control_sigs.alu_op;
    w_src =  control_sigs.w_src;
    reg_rd_au = control_sigs.reg_rd;
  end

  modport au (
    input wen, aluop, port_a, port_b, reg_file_wdata, csr_rdata, w_src,
    imm_UJ_ext, imm_I_ext, j_sel, pc,
    output wdata_au, wen_au, reg_rd_au, busy_au
  );

endinterface

`endif //ARITHMETIC_UNIT_IF_VH
