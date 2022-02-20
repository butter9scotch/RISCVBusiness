`ifndef COMPLETION_BUFFER_IF_VH
`define COMPLETION_BUFFER_IF_VH

interface completion_buffer_if;

  import rv32i_types_pkg::*;

  parameter NUM = 16;

  // DECODE STAGE
  logic [$clog2(NUM)-1:0] cur_tail;
  logic [4:0] vd_final;
  word_t wdata_final;
  word_t epc_final, pc;
  logic alloc_ena, full, empty, scalar_commit_ena, illegal_instr; 

  // TO HAZARD UNIT
  logic flush, exception, branch_mispredict_ena, mal_priv;

  // VECTOR PIPELINE
  logic rv32v_instr, rv32v_commit_ena, rv32v_commit_done, rv32v_exception, rv32v_wb_scalar_ena, rv32v_wb_scalar_ready, rv32v_wb_exception;
  logic [$clog2(NUM)-1:0] rv32v_wb_scalar_index;
  logic [4:0] rv32v_wb_vd;
  word_t rv32v_wb_scalar_data;

  // FPU 
  // TODO: Add signals when integrating FPU
  logic rv32f_commit_ena;

  // FUNCTIONAL UNIT RESULT
  logic [$clog2(NUM)-1:0] index_a, index_mu, index_du, index_ls;
  word_t wdata_a, wdata_mu, wdata_du, wdata_ls;
  logic [4:0] vd_a, vd_mu, vd_du, vd_ls;
  logic exception_a, exception_mu, exception_du, exception_ls;
  logic ready_a, ready_mu, ready_du, ready_ls;
  logic branch_mispredict, wen_a, valid_a, mal_ls;

  logic tb_read;

  modport cb (
    input alloc_ena, rv32v_instr, rv32v_commit_done, rv32v_exception, rv32v_wb_scalar_ena, rv32v_wb_scalar_ready, rv32v_wb_exception, rv32v_wb_scalar_index, rv32v_wb_vd, rv32v_wb_scalar_data, index_a, index_mu, index_du, index_ls, wdata_a, wdata_mu, wdata_du, wdata_ls, vd_a, vd_mu, vd_du, vd_ls, exception_a, exception_mu, exception_du, exception_ls, ready_a, ready_mu, ready_du, ready_ls, branch_mispredict, wen_a, valid_a, mal_ls,
    output cur_tail, vd_final, wdata_final, full, empty, scalar_commit_ena, flush, rv32v_commit_ena, rv32f_commit_ena, exception, branch_mispredict_ena, mal_priv, tb_read
  );

endinterface

`endif // COMPLETION_BUFFER_IF_VH
