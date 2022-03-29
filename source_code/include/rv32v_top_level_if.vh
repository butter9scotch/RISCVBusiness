
`ifndef RV32V_TOP_LEVEL_IF_VH
`define RV32V_TOP_LEVEL_IF_VH

interface rv32v_top_level_if;
  import rv32i_types_pkg::*;

  logic rd_wen;
  logic [4:0] rd_sel;
  logic [31:0] rd_data;
  logic [31:0] instr, rs1_data, rs2_data;
  logic scalar_hazard_if_ret;
  logic returnex;

  modport rv32v (
    output rd_wen,
    output rd_sel,
    output rd_data,
    input instr, rs1_data, rs2_data,
    input scalar_hazard_if_ret,
    input returnex
  );

  modport tb (
    input rd_wen,
    input rd_sel,
    input rd_data,
    output instr, rs1_data, rs2_data,
    output scalar_hazard_if_ret,
    output returnex
  );
endinterface
`endif // RV32V_TOP_LEVEL_IF_VH
