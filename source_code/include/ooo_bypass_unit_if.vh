
`ifndef OOO_BYPASS_UNIT_IF_VH
`define OOO_BYPASS_UNIT_IF_VH

interface ooo_bypass_unit_if();
    import rv32i_types_pkg::*;
    logic [4:0] rs1, rs2;
    logic [4:0] rd_alu, rd_mul, rd_div, rd_lsu;
    logic valid_alu, valid_mul, valid_div, valid_lsu;
    logic rs1_bypass_ena, rs2_bypass_ena;
    word_t rs1_bypass_data, rs2_bypass_data;
    word_t data_alu, data_mul, data_div, data_lsu;
       
    modport bypass_unit (
        input rs1, rs2, rd_alu, rd_mul, rd_div, rd_lsu, valid_alu, valid_mul, valid_div, valid_lsu, data_alu, data_mul, data_div, data_lsu,
        output rs1_bypass_ena, rs2_bypass_ena, rs1_bypass_data, rs2_bypass_data
    );

    modport decode (
        output rs1, rs2,
        input rs1_bypass_ena, rs2_bypass_ena, rs1_bypass_data, rs2_bypass_data
    );
    modport execute (
        output rd_alu, rd_mul, rd_div, rd_lsu, valid_alu, valid_mul, valid_div, valid_lsu, data_alu, data_mul, data_div, data_lsu
    );


endinterface
`endif
