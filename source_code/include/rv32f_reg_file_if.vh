`ifndef RV32F_REG_FILE_IF_VH
`define RV32F_REG_FILE_IF_VH

interface rv32f_reg_file_if();
    
    import rv32i_types_pkg::*;
    import rv32f_types_pkg::*;

    //write and read data
    word_t        f_wdata, f_rs1_data, f_rs2_data;

    //clock and reset
    logic clk, n_rst;

    //register select signals
    logic   [4:0] f_rs1, f_rs2, f_rd; 
    logic [2:0] f_frm_in, f_frm; //rounding mode input and outputs
    logic [4:0] f_flags; //flag outputs

    logic f_wen;
    modport decode (
        output f_rs1, f_rs2,
        input f_rs1_data, f_rs2_data, f_frm
    );

    modport rf (
        input clk, n_rst, f_wdata, f_rs1, f_rs2, f_rd, f_wen, f_flags, f_frm_in, 
        output f_rs1_data, f_rs2_data, f_frm
    );

    modport writeback (
        output f_wdata, f_flags, f_wen, f_rd
    );

endinterface

`endif
