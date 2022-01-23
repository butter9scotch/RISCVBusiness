`ifndef RV32V_EXECUTE_MEMORY_IF_VH
`define RV32V_EXECUTE_MEMORY_IF_VH

interface rv32v_execute_memory_if;
  import rv32i_types_pkg::*;

  logic load_ena, store_ena;
  logic [1:0] wen;
  logic [31:0] storedata0, storedata1, aluresult0, aluresult1;
  offset_t woffset0, woffset1;
  cfgsel_t config_type;
  logic [7:0] vtype, next_vtype_csr;
  logic [31:0] next_avl_csr;
  // logic [VLEN_WIDTH:0] vl; 
  logic [31:0] vl;
  sew_t eew;
  logic single_bit_write, ls_idx;
  logic [4:0] vd;
  logic [31:0] vstart;
  logic [4:0]  rd_sel;
  logic [31:0] rd_data;
  logic  rd_wen;
  width_t eew_loadstore;
  int tb_line_num; //TESTBENCH ONLY



  modport execute (
    output load_ena, store_ena, storedata0, storedata1, aluresult0, aluresult1, wen, woffset0, woffset1,
    config_type, vl, vtype, eew, vd, single_bit_write, vstart, next_vtype_csr, next_avl_csr, eew_loadstore, ls_idx,
    rd_sel, rd_data, rd_wen,
    tb_line_num //TESTBENCH ONLY

  );


  modport memory (
    input load_ena, store_ena, storedata0, storedata1, aluresult0, aluresult1, wen, woffset0, woffset1,
    config_type, vtype, eew, vl, vd, single_bit_write, vstart, next_vtype_csr, next_avl_csr, eew_loadstore, ls_idx,
    rd_sel, rd_data, rd_wen ,
    tb_line_num //TESTBENCH ONLY

  );

endinterface

`endif // RV32V_EXECUTE_MEMORY_IF_VH
