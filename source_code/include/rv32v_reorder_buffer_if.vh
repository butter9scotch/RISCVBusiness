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
 
  // VECTOR REGISTER
  logic vreg_wen;

  // FUNCTIONAL UNIT RESULT
  rob_fu_result_t a_sigs, mu_sigs, du_sigs, m_sigs, p_sigs, ls_sigs;

  modport rob (
    input a_sigs, mu_sigs, du_sigs, m_sigs, p_sigs, ls_sigs,
<<<<<<< Updated upstream
    alloc_ena, sew, lmul, branch_mispredict, scalar_exception, commit_ena, vl, single_bit_op,  
    single_bit_write,
    output cur_tail, vd_final, wen_final, wdata_final, full, rv32v_exception, commit_done, single_wen, single_wen_vl, vreg_wen
=======

    alloc_ena, sew, lmul, branch_mispredict, scalar_exception, commit_ena, vl, 
    single_bit_op, single_bit_write, 
    output cur_tail, vd_final, wen_final, wdata_final, full, rv32v_exception, commit_done, single_wen, single_wen_vl
>>>>>>> Stashed changes
  );

  modport memory (
    output a_sigs, mu_sigs, du_sigs, m_sigs, p_sigs, ls_sigs,
           single_bit_write,
           sew, lmul, branch_mispredict, scalar_exception, commit_ena, vl,  single_bit_op,
    output cur_tail, vd_final, wen_final, wdata_final, full, rv32v_exception, commit_done, single_wen, single_wen_vl
  );
  
  // Alloc_ena comes from scalar decode stage. 
//  modport decode (
//  ); 

endinterface

`endif // RV32V_REORDER_BUFFER_IF_VH
