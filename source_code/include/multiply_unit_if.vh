`ifndef MULTIPLY_UNIT_IF_VH
`define MULTIPLY_UNIT_IF_VH

interface multiply_unit_if();

  import rv32i_types_pkg::*;

  logic [31:0] wdata_mu, rs1_data, rs2_data; 
  logic [1:0] is_signed_mul;
  logic start_mu;
  logic busy_mu, exception_mu, next_busy_mu, done_mu, high_low_sel, decode_done;
  sign_type_t is_signed;

  modport execute (
    input   rs1_data, rs2_data, start_mu,  
     high_low_sel, decode_done, is_signed,
    output  wdata_mu, busy_mu, exception_mu, next_busy_mu, done_mu
  );

endinterface

`endif //MULTIPLY_UNIT_IF_VH