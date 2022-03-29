`ifndef RV32V_ARITHMETIC_UNIT_IF_VH
`define RV32V_ARITHMETIC_UNIT_IF_VH

interface rv32v_arithmetic_unit_if();


  logic [31:0] wdata_a, vs1_data, vs2_data, vs3_data; 
  logic busy_a, exception_a;
  logic start, reduction_ena, rev, mask, adc_sbc, carry_borrow_ena; 
  logic carryin_ena, win, zext_w, woutu,  
  logic vd_widen, is_masked, vd_narrow,
  athresult_t result_type;
  offset_t offset, index;
  valuop_t aluop;
  sew_t sew;  
  comp_t comp_type; 
  mm_t minmax_type; 
  ext_t ext_type; 
  sign_type_t is_signed;

  modport varithmetic_unit (
    input   vs1_data, vs2_data, vs3_data, result_type, offset, aluop, start, reduction_ena, 
    rev, mask, adc_sbc, carry_borrow_ena, sew,  comp_type, minmax_type, ext_type, carryin_ena, 
    win, zext_w, woutu, index, vd_widen, is_signed, is_masked, vd_narrow,
    output  wdata_a, busy_a, exception_a
  );

endinterface

`endif //RV32V_ARITHMETIC_UNIT_IF_VH