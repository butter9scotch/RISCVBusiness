
`ifndef RV32V_TOP_LEVEL_IF_VH
`define RV32V_TOP_LEVEL_IF_VH

interface rv32v_top_level_if;
  import rv32v_types_pkg::*;

  logic rd_wen;
  logic [4:0] rd_sel;
  logic [31:0] rd_data;
  logic [31:0] xs1, xs2;
  logic scalar_hazard_if_ret;
  logic returnex;

  modport dut (
    output rd_wen,
    output rd_sel,
    output rd_data,
    input xs1, xs2,
    input scalar_hazard_if_ret,
    input returnex
  );

  modport tb (
    input rd_wen,
    input rd_sel,
    input rd_data,
    output xs1, xs2,
    output scalar_hazard_if_ret,
    output returnex
  );
endinterface
`endif // RV32V_TOP_LEVEL_IF_VH