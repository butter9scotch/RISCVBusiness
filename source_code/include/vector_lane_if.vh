`ifndef VECTOR_LANE_IF_VH
`define VECTOR_LANE_IF_VH

interface vector_lane_if;
  import rv32i_types_pkg::*;
  logic[31:0] stride, lane_result;
  fu_t fu_type;
  logic[2:0] load_store_type;
  logic[4:0] SEW_f8;
  athresult_t result_type;
  logic stall_e_m, exception, porta_sel, portb_sel, start_mu, mul_widen_ena, high_low;
  logic [1:0] is_signed_mul;
  logic is_signed_div, div_type, start_div;
  logic[31:0] wdata_a, wdata_m, wdata_p, wdata_ls, wdata_mu, wdata_du, vs1_data, vs2_data, vs3_data, porta0, porta1, portb0, portb1, in_addr, out_addr, mask_32bit, mask_32bit_lane0, mask_32bit_lane1, iota_res, wdata_m_ff1;
  offset_t offset;
  logic start_ma;
  valuop_t aluop;
  comp_t comp_type;
  logic start,  multiply_pos_neg, busy, reduction_ena, rev, mask, adc_sbc, carry_borrow_ena, carryin_ena, win, zext_w, woutu, busy_a, busy_m, busy_p, busy_ls, busy_mu, exception_a, exception_m, exception_p, exception_ls, exception_mu, done_mu;
  multiply_type_t multiply_type;
  sew_t sew;
  mm_t minmax_type;
  ext_t ext_type;
  ma_t mask_type;
  logic busy_du, exception_du;
  sign_type_t is_signed;
  logic next_busy_mu, next_busy;
  logic vd_widen;
  offset_t index;
  logic is_masked, vd_narrow;
  logic  done_du, mul_on;
  logic decode_done; // decode done 3 cycles delayed
  logic mul_wait;
  logic mask_bit_set, mask_bit_set_ff1;
  logic stop_flush;

  modport vector_lane (
    input   vs1_data, vs2_data, vs3_data, stride, fu_type, load_store_type, result_type, offset, aluop, SEW_f8, mask, stall_e_m, reduction_ena, is_signed_mul, multiply_type, multiply_pos_neg, mul_widen_ena, div_type, is_signed_div, win, woutu, zext_w, mask_type, stop_flush,
    mask_32bit_lane0, mask_32bit_lane1, vd_widen, is_masked, vd_narrow, decode_done, mul_wait,
    output  lane_result, busy, next_busy, exception, done_mu, mul_on
  );

  modport varithmetic_unit (
    input   vs1_data, vs2_data, vs3_data, result_type, offset, aluop, start, reduction_ena, rev, mask, adc_sbc, carry_borrow_ena, sew,  comp_type, minmax_type, ext_type, carryin_ena, win, zext_w, woutu, index, vd_widen, is_signed, is_masked, vd_narrow,
    output  wdata_a, busy_a, exception_a
  );

  modport vmultiply_unit (
    input   vs1_data, vs2_data, vs3_data, sew, is_signed_mul, start_mu, multiply_type, multiply_pos_neg, mul_widen_ena, high_low, decode_done, is_signed, stop_flush,
    output  wdata_mu, busy_mu, exception_mu, next_busy_mu, done_mu
  );

  modport vdivide_unit (
    input   vs1_data, vs2_data, start_div, div_type, is_signed_div, is_signed,
    output  wdata_du, busy_du, exception_du, done_du
  );

  modport mask_unit (
    input   vs1_data, vs2_data, start_ma, mask_type, mask_32bit, iota_res, offset, is_masked,
    output  wdata_m, wdata_m_ff1, busy_m, exception_m, mask_bit_set, mask_bit_set_ff1
  );

  modport permutation_unit (
    input   vs1_data, vs2_data, 
    output  wdata_p, busy_p, exception_p
  );

  modport vloadstore_unit (
    input   porta0, porta1, portb0, portb1, porta_sel, portb_sel,
    output  in_addr, out_addr, wdata_ls
  );

endinterface

`endif //VECTOR_LANE_IF_VH
