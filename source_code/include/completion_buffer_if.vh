`ifndef COMPLETION_BUFFER_IF_VH
`define COMPLETION_BUFFER_IF_VH

interface completion_buffer_if();

  import rv32i_types_pkg::*;

  parameter NUM = 16;
  
  logic halt_instr;

  // DECODE STAGE
  logic [$clog2(NUM_CB_ENTRY)-1:0] cur_tail;
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
  logic [$clog2(NUM_CB_ENTRY)-1:0] rv32v_wb_scalar_index;
  logic [4:0] rv32v_wb_vd;
  word_t rv32v_wb_scalar_data;
  opcode_t opcode;
  opcode_t opcode_commit;

  //FPU
  logic rv32f_commit_ena;

  //FUNCTIONAL UNIT RESULT
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_ls;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_sfu;
  word_t wdata_ls;
  word_t wdata_sfu;
  word_t address_a;
  word_t address_ls;
  word_t epc;
  logic [4:0] vd_ls;
  logic [4:0] vd_sfu;
  logic exception_ls;
  logic exception_sfu;
  logic ready_ls;
  logic ready_sfu;
  logic branch_mispredict;
  logic wen_ls;
  logic wen_sfu;
  logic valid_a;
  logic mal_ls;
  cpu_tracker_signals_t CPU_TRACKER, CPU_TRACKER_decode;

  logic tb_read;

  modport cb (
    input alloc_ena, rv32v_instr, rv32v_commit_done, rv32v_exception, rv32v_wb_scalar_ena, rv32v_wb_scalar_ready, 
           rv32v_wb_exception, exception_ls, exception_sfu, ready_ls, ready_sfu, branch_mispredict, wen_ls, 
           mal_ls, rv32v_wb_scalar_index, index_ls, index_sfu, 
           rv32v_wb_vd, vd_ls, vd_sfu, rv32v_wb_scalar_data, wen_sfu,
           wdata_ls, wdata_sfu, CPU_TRACKER_decode, opcode,
    output full, empty, scalar_commit_ena, flush, rv32v_commit_ena, rv32f_commit_ena, 
           exception, branch_mispredict_ena, mal_priv, tb_read, cur_tail, vd_final, 
           wdata_final, halt_instr, CPU_TRACKER, epc
  );

  modport decode (
    input cur_tail, full, empty,
    output alloc_ena, rv32v_instr, rv32v_wb_scalar_ena, opcode, CPU_TRACKER_decode
  );

  modport writeback (
    input mal_priv, CPU_TRACKER
  );

  modport execute (
    input index_ls, index_sfu, wdata_ls, wdata_sfu, vd_ls, vd_sfu, exception_ls, exception_sfu, ready_ls, ready_sfu, branch_mispredict, wen_ls, wen_sfu, valid_a, mal_ls, CPU_TRACKER, opcode, halt_instr
  );

  modport hu (
    input full, empty, flush, exception, branch_mispredict_ena, mal_priv, epc
  );

  modport rv32v (
    input rv32v_commit_done, rv32v_exception, rv32v_wb_scalar_ready, rv32v_wb_exception, rv32v_wb_scalar_index, rv32v_wb_vd, rv32v_commit_ena,
    output rv32v_wb_scalar_data
  );


endinterface

`endif //COMPLETION_BUFFER_IF_VH
