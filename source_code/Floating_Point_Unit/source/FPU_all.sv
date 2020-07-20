
//created by Sean Hsu
//Modified by Xinlue Liu, Zhengsen Fu
//Last Updated  : 7/19/20

`include "FPU_if.svh"
`include "register_FPU_if.svh"

module FPU_all
(
 input 	       clk,
 input 	       nrst,
 FPU_if.fp fpa_if,
 register_FPU_if.fp frf_fp,
 register_FPU_if.rf frf_rf
 );
//logic [31:0] f_rs1_data, f_rs2_data;

//logic [7:0] f_funct_7;

//fpu load. 2 to 1 multiplexer choose between dload_ext[31:0] and FPU_out[31:0] from fpu
//logic [31:0] f_w_data;
assign frf_rf.f_w_data = fpa_if.f_LW ? frf_fp.FPU_out : fpa_if.dload_ext;

typedef enum bit[2:0] {IDLE, START, READY} stateType; //state machine to identify f_ready
reg [2:0] STATE;
reg [2:0] NXT_STATE;
reg [31:0] nxt_f_rs1_data, nxt_f_rs2_data;
reg [7:0] nxt_f_funct_7;
reg [2:0] nxt_frm;
logic f_ready;
always_ff @ (negedge nrst, posedge clk)
	begin: REG_LOGIC
	if (!nrst) begin
		STATE <= IDLE;
		frf_fp.f_rs1_data <= 0;
		frf_fp.f_rs2_data <= 0;
		frf_fp.funct_7 <= 0;
		frf_fp.frm <= 0;
	end else begin
		STATE <= NXT_STATE;
		frf_fp.f_rs1_data <= nxt_f_rs1_data;
		frf_fp.f_rs2_data <= nxt_f_rs2_data;
		frf_fp.funct_7 <= nxt_f_funct_7;
		frf_fp.frm <= nxt_frm;
	end
end

always_comb 
	begin: NXT_LOGIC
	NXT_STATE = STATE;
	
	case(STATE)
	IDLE: begin
		if ((nxt_f_rs1_data != frf_fp.f_rs1_data) | (nxt_f_rs2_data != frf_fp.f_rs2_data) | (nxt_f_funct_7 != frf_fp.funct_7) | (nxt_frm != frf_fp.frm)) begin
			NXT_STATE = START;
		end else begin
			NXT_STATE = IDLE;
		end
	end
	START: begin
		NXT_STATE = READY;
	end
	READY: begin
		NXT_STATE = IDLE;
	end
	endcase
end

always_comb
	begin: OUTPUT_LOGIC
	frf_rf.f_ready = 1'b0;
	case (STATE) 
	READY: begin
	frf_rf.f_ready = 1'b1;
	end
	endcase
end

FPU_top_level FPU(
.clk(clk), 
.nrst(nrst),
.floating_point1(frf_fp.f_rs1_data),
.floating_point2(frf_fp.f_rs2_data),
.frm(frf_fp.frm),
.funct7(frf_fp.funct_7),
.floating_point_out(frf_fp.FPU_out),
.flags(frf_fp.flags),
);

f_register_file(
.clk(clk),
.nrst(nrst),
.f_w_data(frf_rf.f_w_data),
.f_rs1(frf_rf.f_rs1), 
.f_rs2(frf_rf.f_rs2),
.f_rd(frf_rf.f_rd),
.f_wen(frf_rf.f_wen),
.f_NV(frf_rf.flags[4]),
.f_DZ(frf_rf.flags[3]),  
.f_OF(frf_rf.flags[2]),
.f_UF(frf_rf.flags[1]),
.f_NX(frf_rf.flags[0]),
.f_frm_in(frf_rf.f_frm_in),
.f_ready(frf_rf.f_ready), //ready signal
.f_SW(fpa_if.f_SW) //sw signal
.f_frm_out(frf_rf.f_frm_out),
.f_rs1_data(frf_rf.f_rs1_data),
.f_rs2_data(frf_rf.f_rs2_data),
.f_flags(frf_rf.f_flags)
);

endmodule
