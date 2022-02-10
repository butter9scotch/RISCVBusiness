`ifndef DIVIDE_UNIT_IF_VH
`define DIVIDE_UNIT_IF_VH

interface divide_unit_if();
  
  logic [31:0] rs1_data, rs2_data, wdata_du; 
  logic is_signed_div, div_type, start_div;
  //sign_type_t is_signed;
  logic busy_du, exception_du, done_du;

  modport execute (
    input   rs1_data, rs2_data, start_div, div_type, is_signed_div, 
    output  wdata_du, busy_du, exception_du, done_du
  );

endinterface

`endif //DIVIDE_UNIT_IF_VH