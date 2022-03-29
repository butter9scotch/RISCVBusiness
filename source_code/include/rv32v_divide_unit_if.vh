`ifndef RV32V_DIVIDE_UNIT_IF_VH
`define RV32V_DIVIDE_UNIT_IF_VH

interface rv32v_divide_unit_if();

  logic [31:0] vs1_data, vs2_data, wdata_du; 
  logic is_signed_div, div_type, start_div;
  sign_type_t is_signed;
  logic busy_du, exception_du, done_du;

  modport divide_unit (
    input   vs1_data, vs2_data, start_div, div_type, is_signed_div, is_signed,
    output  wdata_du, busy_du, exception_du, done_du
  );

endinterface

`endif //RV32V_DIVIDE_UNIT_IF_VH