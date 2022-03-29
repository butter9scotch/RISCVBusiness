`ifndef RV32V_REORDER_BUFFER_IF_VH
`define RV32V_REORDER_BUFFER_IF_VH

interface rv32v_reorder_buffer_if;

  import rv32i_types_pkg::*;

  parameter NUM = 32;
  parameter LANES = 2;

  // DECODE STAGE
  logic [$clog2(NUM)-1:0] cur_tail;
  logic [4:0] vd_final;
  logic [15:0] wen_final;
  logic [VLEN-1:0] wdata_final;
  logic alloc_ena, full, single_bit_write, single_bit_op, single_wen; 
  logic [VL_WIDTH:0] single_wen_vl;

  // CSR
  logic [VL_WIDTH:0] vl;
  sew_t sew;
  vlmul_t lmul;

  // SCALAR PIPELINE
  logic branch_mispredict, scalar_exception, rv32v_exception;

  // COMPLETION BUFFER
  logic commit_ena, commit_done;

  // FUNCTIONAL UNIT RESULT
  logic [$clog2(NUM)-1:0] index_a, index_mu, index_du, index_m, index_p, index_ls;
  logic [VL_WIDTH:0] vl_a, vl_mu, vl_du, vl_m, vl_p, vl_ls;
  sew_t sew_a, sew_mu, sew_du, sew_m, sew_p, sew_ls;
  offset_t woffset_a, woffset_mu, woffset_du, woffset_m, woffset_p, woffset_ls;
  offset_t exception_index_a, exception_index_mu, exception_index_du, exception_index_m, exception_index_p, exception_index_ls;
  logic [63:0] wdata_a, wdata_mu, wdata_du, wdata_m, wdata_p, wdata_ls;
  logic [4:0] vd_a, vd_mu, vd_du, vd_m, vd_p, vd_ls;
  logic [1:0] wen_a, wen_mu, wen_du, wen_m, wen_p, wen_ls;
  logic exception_a, exception_mu, exception_du, exception_m, exception_p, exception_ls;
  logic ready_a, ready_mu, ready_du, ready_m, ready_p, ready_ls;

  modport rob (
    input index_a, index_mu, index_du, index_m, index_p, index_ls, woffset_a, woffset_mu, woffset_du, woffset_m, woffset_p, woffset_ls, wdata_a, wdata_mu, wdata_du, wdata_m, wdata_p, wdata_ls, vd_a, vd_mu, vd_du, vd_m, vd_p, vd_ls, wen_a, wen_mu, wen_du, wen_m, wen_p, wen_ls, exception_a, exception_mu, exception_du, exception_m, exception_p, exception_ls, ready_a, ready_mu, ready_du, ready_m, ready_p, ready_ls, alloc_ena, sew, lmul, branch_mispredict, scalar_exception, commit_ena, vl, exception_index_a, exception_index_mu, exception_index_du, exception_index_m, exception_index_p, exception_index_ls, sew_a, sew_mu, sew_du, sew_m, sew_p, sew_ls, single_bit_write, vl_a, vl_mu, vl_du, vl_m, vl_p, vl_ls, single_bit_op,
    output cur_tail, vd_final, wen_final, wdata_final, full, rv32v_exception, commit_done, single_wen, single_wen_vl
  );

  modport memory (
    output index_a, index_mu, index_du, index_m, index_p, index_ls, 
           woffset_a, woffset_mu, woffset_du, woffset_m, woffset_p, woffset_ls, 
           wdata_a, wdata_mu, wdata_du, wdata_m, wdata_p, wdata_ls, 
           vd_a, vd_mu, vd_du, vd_m, vd_p, vd_ls, 
           wen_a, wen_mu, wen_du, wen_m, wen_p, wen_ls, 
           exception_a, exception_mu, exception_du, exception_m, exception_p, exception_ls, 
           ready_a, ready_mu, ready_du, ready_m, ready_p, ready_ls, 
           exception_index_a, exception_index_mu, exception_index_du, exception_index_m, exception_index_p, exception_index_ls, 
           sew_a, sew_mu, sew_du, sew_m, sew_p, sew_ls, 
           vl_a, vl_mu, vl_du, vl_m, vl_p, vl_ls,
           single_bit_write,
           sew, lmul, branch_mispredict, scalar_exception, commit_ena, vl,  single_bit_op,
    output cur_tail, vd_final, wen_final, wdata_final, full, rv32v_exception, commit_done, single_wen, single_wen_vl
  );
  
  modport decode (
    output alloc_ena
  ); 

endinterface

`endif // RV32V_REORDER_BUFFER_IF_VH
