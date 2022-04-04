`include "pipe5_forwarding_unit_if.vh"


module pipe5_forwarding_unit (
    pipe5_forwarding_unit_if.forwarding_unit bypass_if
);
    import pipe5_types_pkg::*;

    always_comb begin : FORWARD_RS1
        if(bypass_if.rs1_ex == bypass_if.rd_mem && bypass_if.WEN_mem
            && bypass_if.rd_mem != '0) begin
            bypass_if.bypass_rs1 = FWD_M;
        end else if(bypass_if.rs1_ex == bypass_if.rd_wb && bypass_if.WEN_wb
            && bypass_if.rd_wb != '0) begin
            bypass_if.bypass_rs1 = FWD_W;
        end else begin
            bypass_if.bypass_rs1 = NO_FWD;
        end
    end

    always_comb begin : FORWARD_RS2
        if(bypass_if.rs2_ex == bypass_if.rd_mem && bypass_if.WEN_mem) begin
            bypass_if.bypass_rs2 = FWD_M;
        end else if(bypass_if.rs2_ex == bypass_if.rd_wb && bypass_if.WEN_wb) begin
            bypass_if.bypass_rs2 = FWD_W;
        end else begin
            bypass_if.bypass_rs2 = NO_FWD;
        end
    end

    always_comb begin : FORWARD_F_RS1
        if(bypass_if.f_rs1_ex == bypass_if.f_rd_mem && bypass_if.f_WEN_mem) begin
            bypass_if.bypass_f_rs1 = FWD_M;
        end else if(bypass_if.f_rs1_ex == bypass_if.f_rd_wb && bypass_if.f_WEN_wb) begin
            bypass_if.bypass_f_rs1 = FWD_W;
        end else begin
            bypass_if.bypass_f_rs1 = NO_FWD;
        end
    end

    always_comb begin : FORWARD_F_RS2
        if(bypass_if.f_rs2_ex == bypass_if.f_rd_mem && bypass_if.f_WEN_mem) begin
            bypass_if.bypass_f_rs2 = FWD_M;
        end else if(bypass_if.f_rs2_ex == bypass_if.f_rd_wb && bypass_if.f_WEN_wb) begin
            bypass_if.bypass_f_rs2 = FWD_W;
        end else begin
            bypass_if.bypass_f_rs2 = NO_FWD;
        end
    end
 endmodule
