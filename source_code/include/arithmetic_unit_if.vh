`ifndef ARITHMETIC_UNIT_IF_VH
`define ARITHMETIC_UNIT_IF_VH

interface arithmetic_unit_if();

  import alu_types_pkg::*;
  import rv32i_types_pkg::word_t;

  logic wen;
  aluop_t aluop;
  word_t port_a;
  word_t port_b;
  word_t reg_file_wdata;
  word_t csr_rdata;
  w_src_t w_src;
  word_t wdata_au;
  logic wen_au;
  word_t imm_UJ_ext;
  word_t imm_I_ext;

  modport au (
    input wen, aluop, port_a, port_b, reg_file_wdata, csr_rdata, w_src,
    imm_UJ_ext, imm_I_ext,
    output wdata_au, wen_au
  );

endinterface

`endif //ARITHMETIC_UNIT_IF_VH