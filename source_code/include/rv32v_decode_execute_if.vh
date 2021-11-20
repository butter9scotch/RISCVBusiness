`ifndef RV32V_DECODE_EXECUTE_IF_VH
`define RV32V_DECODE_EXECUTE_IF_VH

interface rv32v_decode_execute_if;
  import rv32v_types_pkg::*;

  logic stride_type, rd_WEN, config_type, mask0, mask1, reduction_ena, is_signed, ls_idx, load, store, wen0, wen1, vill;
  logic [31:0] stride_val, xs1, xs2,  vs1_lane0, vs1_lane1, vs3_lane0, vs3_lane1, vs2_lane0, vs2_lane1, imm, storedata0, storedata1;
  logic [4:0] rd_sel, vd;
  offset_t woffset0, woffset1;
  fu_t fu_type;
  athresult_t result_type;
  valuop_t aluop;
  rs_t rs1_type, rs2_type;
  logic [4:0] uop_vl;
  vlmul_t lmul;
  sew_t sew,  eew;
  logic [VL_WIDTH:0] vstart, vlenb, vtype; //[1, 128]
  logic [31:0] vl;
  mm_t minmax_type;


  logic div_type;
  logic is_signed_div;
  logic high_low;
  logic [1:0] is_signed_mul;
  logic mul_widen_ena;
  logic multiply_pos_neg;
  logic multiply_type;

  logic adc_sbc;
  logic carry_borrow_ena;
  logic carryin_ena;
  logic comp_type;
  logic rev;
  ext_t ext_type;
  // logic index;
  logic win;
  logic woutu;
  logic zext_w;
  logic single_bit_write;

  ma_t mask_type;
  logic out_inv;
  logic in_inv;
  logic[31:0] mask_32bit_lane0, mask_32bit_lane1;
  // logic shamt;




  modport decode (
    output stride_type, stride_val, xs1, xs2, rd_WEN, config_type, rd_sel, 
    eew, vl, vlenb, 
    vs1_lane0, vs1_lane1, vs3_lane0, vs3_lane1, rs1_type, imm, rs2_type, vs2_lane0, 
    vs2_lane1, fu_type, result_type, woffset0, woffset1, aluop, mask0, mask1, 
    reduction_ena, is_signed, ls_idx, load, store, storedata0, storedata1, wen0, wen1,
    minmax_type, multiply_type, multiply_pos_neg, mul_widen_ena, high_low, div_type, is_signed_div, is_signed_mul, vtype,
    lmul, sew,
    adc_sbc, carry_borrow_ena, carryin_ena, comp_type, rev, ext_type,
    win, woutu, zext_w, vd, single_bit_write, mask_type, out_inv, in_inv, mask_32bit_lane0, mask_32bit_lane1
  );

  modport execute (
    input stride_type, stride_val, xs1, xs2, rd_WEN, config_type, rd_sel, vs1_lane0, 
    vs1_lane1, vs3_lane0, vs3_lane1, rs1_type, imm, rs2_type, vs2_lane0, vs2_lane1, fu_type, 
    result_type, woffset0, woffset1, aluop, mask0, mask1, reduction_ena, is_signed, ls_idx, 
    load, store, storedata0, storedata1, wen0, wen1, minmax_type,
    eew, lmul, sew, vl, vlenb, multiply_type, multiply_pos_neg, mul_widen_ena, high_low, div_type, is_signed_div, is_signed_mul,
    vtype,
    adc_sbc, carry_borrow_ena, carryin_ena, comp_type, rev, ext_type, win, woutu, zext_w,
    vd, single_bit_write, mask_type, out_inv, in_inv, mask_32bit_lane0, mask_32bit_lane1
  );

endinterface

`endif // RV32V_DECODE_EXECUTE_IF_VH
