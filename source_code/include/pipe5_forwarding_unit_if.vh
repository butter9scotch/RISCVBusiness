
`ifndef PIPE5_FORWARDING_UNIT_IF_VH
`define PIPE5_FORWARDING_UNIT_IF_VH

interface pipe5_forwarding_unit_if();
    import pipe5_types_pkg::*;
    import rv32i_types_pkg::*;

    bypass_t bypass_rs1, bypass_rs2;
    word_t rs1_ex, rs2_ex, rd_mem, rd_wb;
    word_t rd_data_mem, rd_data_wb;
    logic WEN_mem, WEN_wb;


    modport forwarding_unit (
        input rs1_ex, rs2_ex, rd_mem, rd_wb, WEN_mem, WEN_wb,
        output bypass_rs1, bypass_rs2
    );
    modport execute (
        output rs1_ex, rs2_ex,
        input bypass_rs1, bypass_rs2, rd_data_mem, rd_data_wb
    );
    modport memory (
        output rd_mem, WEN_mem, rd_data_mem
    );
    modport writeback (
        output rd_wb, WEN_wb, rd_data_wb
    );

endinterface
`endif
