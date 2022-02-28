`ifndef COMPLETION_BUFFER_IF_VH
`define COMPLETION_BUFFER_IF_VH

interface completion_buffer_if();

  import rv32i_types_pkg::*;

  parameter NUM = 16;
  
  logic halt_instr;

  // DECODE STAGE
  logic [$clog2(NUM)-1:0] cur_tail;
  logic [4:0] vd_final;
  word_t wdata_final;
  logic alloc_ena;
  logic full;
  logic empty;
  logic scalar_commit_ena;
  logic illegal_instr;

  // TO HAZARD UNIT
  logic flush;
  logic exception;
  logic branch_mispredict_ena;
  logic mal_priv;

  //VECTOR PIPELINE
  logic rv32v_instr;
  logic rv32v_commit_ena;
  logic rv32v_commit_done;
  logic rv32v_exception;
  logic rv32v_wb_scalar_ena;
  logic rv32v_wb_scalar_ready;
  logic rv32v_wb_exception;
  logic [$clog2(NUM)-1:0] rv32v_wb_scalar_index;
  logic [4:0] rv32v_wb_vd;
  word_t rv32v_wb_scalar_data;

  //FPU
  logic rv32f_commit_ena;

  //FUNCTIONAL UNIT RESULT
  logic [$clog2(NUM)-1:0] index_a;
  logic [$clog2(NUM)-1:0] index_mu;
  logic [$clog2(NUM)-1:0] index_du;
  logic [$clog2(NUM)-1:0] index_ls;
  word_t wdata_a;
  word_t wdata_mu;
  word_t wdata_du;
  word_t wdata_ls;
  logic [4:0] vd_a;
  logic [4:0] vd_mu;
  logic [4:0] vd_du;
  logic [4:0] vd_ls;
  logic exception_a;
  logic exception_mu;
  logic exception_du;
  logic exception_ls;
  logic ready_a;
  logic ready_mu;
  logic ready_du;
  logic ready_ls;
  logic branch_mispredict;
  logic wen_a;
  logic valid_a;
  logic mal_ls;
  cpu_tracker_signals_t CPU_TRACKER;

  logic tb_read;

  modport cb (
    input alloc_ena, rv32v_instr, rv32v_commit_done, rv32v_exception, rv32v_wb_scalar_ena, rv32v_wb_scalar_ready, 
           rv32v_wb_exception, exception_a, exception_mu, exception_du, exception_ls, ready_a, 
           ready_mu, ready_du, ready_ls, branch_mispredict, wen_a, valid_a, 
           mal_ls, rv32v_wb_scalar_index, index_a, index_mu, index_du, index_ls, 
           rv32v_wb_vd, vd_a, vd_mu, vd_du, vd_ls, rv32v_wb_scalar_data, 
           wdata_a, wdata_mu, wdata_du, wdata_ls, CPU_TRACKER,
    output full, empty, scalar_commit_ena, flush, rv32v_commit_ena, rv32f_commit_ena, 
           exception, branch_mispredict_ena, mal_priv, tb_read, cur_tail, vd_final, 
           wdata_final
  );
  modport commit (
    output alloc_ena, rv32v_instr, rv32v_commit_done, rv32v_exception, rv32v_wb_scalar_ena, rv32v_wb_scalar_ready, 
           rv32v_wb_exception, exception_a, exception_mu, exception_du, exception_ls, ready_a, 
           ready_mu, ready_du, ready_ls, branch_mispredict, wen_a, valid_a, 
           mal_ls, rv32v_wb_scalar_index, index_a, index_mu, index_du, index_ls, 
           rv32v_wb_vd, vd_a, vd_mu, vd_du, vd_ls, rv32v_wb_scalar_data, 
           wdata_a, wdata_mu, wdata_du, wdata_ls, halt_instr
  );

  modport decode (
    input cur_tail, full, empty,
    output alloc_ena, rv32v_instr, rv32v_wb_scalar_ena
  );

  modport writeback (
    input index_a, index_mu, index_du, index_ls, wdata_a, wdata_mu, wdata_du, wdata_ls, vd_a, vd_mu, vd_du, vd_ls, exception_a, exception_mu, exception_du, exception_ls, ready_a, ready_mu, ready_du, ready_ls, branch_mispredict, wen_a, valid_a, mal_ls, CPU_TRACKER
  );

  modport hu (
    input full, empty, flush, exception, branch_mispredict_ena, mal_priv
  );

  modport rv32v (
    input rv32v_commit_done, rv32v_exception, rv32v_wb_scalar_ready, rv32v_wb_exception, rv32v_wb_scalar_index, rv32v_wb_vd, rv32v_commit_ena,
    output rv32v_wb_scalar_data
  );

  modport register (
    input vd_final, wdata_final, scalar_commit_ena
  );

endinterface

`endif //COMPLETION_BUFFER_IF_VH
