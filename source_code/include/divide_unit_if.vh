`ifndef DIVIDE_UNIT_IF_VH
`define DIVIDE_UNIT_IF_VH

interface divide_unit_if(input rv32i_types_pkg::div_control_signals_t control_sigs);
  
  logic [31:0] rs1_data; 
  logic [31:0] rs2_data; 
  logic [31:0] wdata_du; 
  logic [4:0] reg_rd; 
  logic [4:0] reg_rd_du; 
  logic wen;
  logic wen_du;
  logic is_signed_div;
  logic div_type;
  logic start_div;
  logic busy_du;
  logic done_du;

  always_comb begin : CONNECTIONS
    wen = control_sigs.wen;
    is_signed_div = control_sigs.is_signed;
    div_type = control_sigs.div_type;
    start_div = control_sigs.ena;
    reg_rd = control_sigs.reg_rd;
  end

  modport execute (
    input   rs1_data, rs2_data, start_div, div_type, is_signed_div, 
            wen, reg_rd,
    output  wdata_du, busy_du, done_du, reg_rd_du, wen_du
  );

endinterface

`endif //DIVIDE_UNIT_IF_VH
