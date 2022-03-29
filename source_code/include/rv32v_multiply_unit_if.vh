`ifndef RV32V_MULTIPLY_UNIT_IF_VH
`define RV32V_MULTIPLY_UNIT_IF_VH

interface rv32v_multiply_unit_if();


    logic [31:0] wdata_mu, vs1_data, vs2_data, vs3_data; 
    sew_t sew; 
    logic [1:0] is_signed_mul;
    logic start_mu, mul_widen_ena;
    multiply_type_t multiply_type;
    logic busy_mu, exception_mu, next_busy_mu, done_mu, multiply_pos_neg, high_low, decode_done;
    sign_type_t is_signed;

  modport multiply_unit (
    input   vs1_data, vs2_data, vs3_data, sew, is_signed_mul, start_mu, multiply_type, 
    multiply_pos_neg, mul_widen_ena, high_low, decode_done, is_signed,
    output  wdata_mu, busy_mu, exception_mu, next_busy_mu, done_mu
  );

endinterface

`endif //RV32V_MULTIPLY_UNIT_IF_VH