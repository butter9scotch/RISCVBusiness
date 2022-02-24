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
  word_t wdata_au;
  logic wen_au;

  modport execute (
    input wen, aluop, port_a, port_b, reg_file_wdata, csr_rdata, 
    output wdata_au, wen_au
  );

endinterface

`endif //ARITHMETIC_UNIT_IF_VH