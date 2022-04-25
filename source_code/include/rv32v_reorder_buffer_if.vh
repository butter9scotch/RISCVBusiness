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
  logic counter_done;

  // SCALAR PIPELINE
  logic branch_mispredict, scalar_exception, v_exception;
  logic rd_wen;

  // COMPLETION BUFFER
  logic commit_ena, commit_done;
 
  // VECTOR REGISTER
  logic vreg_wen;
  logic v_done;

  // FUNCTIONAL UNIT RESULT
  rob_fu_result_t a_sigs, mu_sigs, du_sigs, m_sigs, p_sigs, ls_sigs;

  logic cou_done;
  offset_t cou_ori_offset;

  modport rob (
    input a_sigs, mu_sigs, du_sigs, m_sigs, p_sigs, ls_sigs, cou_done, cou_ori_offset,
    alloc_ena, sew, lmul, branch_mispredict, scalar_exception, commit_ena, vl, single_bit_op,  
    single_bit_write, counter_done, rd_wen, 
    output cur_tail, vd_final, wen_final, wdata_final, full, v_exception, commit_done, v_done, single_wen, single_wen_vl, vreg_wen

  );

  modport memory (
    output a_sigs, mu_sigs, du_sigs, m_sigs, p_sigs, ls_sigs,
           single_bit_write,
           sew, branch_mispredict, scalar_exception, commit_ena, vl,  single_bit_op,
    output cur_tail, vd_final, wen_final, wdata_final, full, v_exception, commit_done, single_wen, single_wen_vl,
           counter_done, rd_wen, cou_done, cou_ori_offset
  );

  modport execute (
    input v_done
  );
  
  // Alloc_ena comes from scalar decode stage. 
  modport decode (
    input cur_tail, v_done
  ); 

endinterface

`endif // RV32V_REORDER_BUFFER_IF_VH
