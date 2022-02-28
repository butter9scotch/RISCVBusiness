`ifndef ARITHMETIC_UNIT_IF_VH
`define ARITHMETIC_UNIT_IF_VH

interface arithmetic_unit_if(input arith_control_signals_t control_sigs);

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

  always_comb begin : CONNECTIONS
    wen = control_sigs.wwen;
    aluop = control_sigs.alu_op;
    w_src =  control_sigs.w_src;
    reg_rd = control_sigs.reg_rd;
  end

  modport execute (
    input wen, aluop, port_a, port_b, reg_file_wdata, csr_rdata, w_src,
    output wdata_au, wen_au
  );

endinterface

`endif //ARITHMETIC_UNIT_IF_VH