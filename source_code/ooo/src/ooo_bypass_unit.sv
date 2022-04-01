`include "ooo_bypass_unit_if.vh"


module ooo_bypass_unit (
    ooo_bypass_unit_if.bypass_unit bypass_if
);
  import rv32i_types_pkg::*;

  logic rs1_not_zero;
  logic rs2_not_zero;
  logic rs1_match_alu;
  logic rs1_match_mul;
  logic rs1_match_div;
  logic rs1_match_lsu;
  logic rs2_match_alu;
  logic rs2_match_mul;
  logic rs2_match_div;
  logic rs2_match_lsu;

  assign rs1_not_zero = bypass_if.rs1 != '0;
  assign rs2_not_zero = bypass_if.rs2 != '0;

  assign rs1_match_alu  = bypass_if.rs1 == bypass_if.rd_alu & bypass_if.valid_alu & rs1_not_zero;
  assign rs1_match_mul  = bypass_if.rs1 == bypass_if.rd_mul & bypass_if.valid_mul & rs1_not_zero;
  assign rs1_match_div  = bypass_if.rs1 == bypass_if.rd_div & bypass_if.valid_div & rs1_not_zero;
  assign rs1_match_lsu  = bypass_if.rs1 == bypass_if.rd_lsu & bypass_if.valid_lsu & rs1_not_zero;

  assign rs2_match_alu  = bypass_if.rs2 == bypass_if.rd_alu & bypass_if.valid_alu & rs2_not_zero;
  assign rs2_match_mul  = bypass_if.rs2 == bypass_if.rd_mul & bypass_if.valid_mul & rs2_not_zero;
  assign rs2_match_div  = bypass_if.rs2 == bypass_if.rd_div & bypass_if.valid_div & rs2_not_zero;
  assign rs2_match_lsu  = bypass_if.rs2 == bypass_if.rd_lsu & bypass_if.valid_lsu & rs2_not_zero;

  assign bypass_if.rs1_bypass_ena = rs1_match_alu | rs1_match_mul | rs1_match_div | rs1_match_lsu;
  assign bypass_if.rs2_bypass_ena = rs2_match_alu | rs2_match_mul | rs2_match_div | rs2_match_lsu;

  //assign bypass_if.rs1_bypass_ena = 0; 
  //assign bypass_if.rs2_bypass_ena = 0;

  assign bypass_if.rs1_bypass_data = rs1_match_alu ? bypass_if.data_alu :
                                     rs1_match_mul ? bypass_if.data_mul :
                                     rs1_match_div ? bypass_if.data_div :
                                     bypass_if.data_lsu;

  assign bypass_if.rs2_bypass_data = rs2_match_alu ? bypass_if.data_alu :
                                     rs2_match_mul ? bypass_if.data_mul :
                                     rs2_match_div ? bypass_if.data_div :
                                     bypass_if.data_lsu;

 endmodule
