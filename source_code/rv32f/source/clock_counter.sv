`include "FPU_if.vh"
module clock_counter (
    FPU_if.cc frf_cc
);
  typedef enum bit[2:0] {IDLE, START, READY} stateType; //state machine to identify f_ready
  stateType STATE;
  stateType NXT_STATE;
  reg [31:0] nxt_f_rs1_data, nxt_f_rs2_data;
  reg [31:0] last_f_rs1_data, last_f_rs2_data;
  
  reg [7:0] nxt_f_funct_7;
  reg [7:0] last_f_funct_7;

  reg [2:0] nxt_frm;
  reg [2:0] last_frm;

  logic f_ready;
  always_ff @ (negedge frf_cc.n_rst, posedge frf_cc.clk)
    begin: REG_LOGIC
    if (!frf_cc.n_rst) begin
      STATE <= IDLE;
      last_f_rs1_data <= 0;
      last_f_rs2_data <= 0;
      last_f_funct_7 <= 0;
      last_frm <= 0;
    end else begin
      STATE <= NXT_STATE;
      last_f_rs1_data <= nxt_f_rs1_data;
      last_f_rs2_data <= nxt_f_rs2_data;
      last_f_funct_7 <= nxt_f_funct_7;
      last_frm <= nxt_frm;
    end
  end

  always_comb begin: NXT_LOGIC
    NXT_STATE = STATE;
    case(STATE)
    IDLE: begin
      if ((last_f_rs1_data != frf_cc.port_a) || (last_f_rs2_data != frf_cc.port_b) || (last_f_funct_7 != frf_cc.f_funct_7) || (last_frm != frf_cc.f_frm_in)) begin
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

  always_comb begin: OUTPUT_LOGIC
    frf_cc.f_ready = 1'b0;
    nxt_f_rs1_data = last_f_rs1_data;
    nxt_f_rs2_data = last_f_rs2_data;
    nxt_f_funct_7 = last_f_funct_7;
    nxt_frm = last_frm;
    case (STATE) 
    READY: begin
    frf_cc.f_ready = 1'b1;
    end
    IDLE: begin
      nxt_f_rs1_data = frf_cc.port_a;
      nxt_f_rs2_data = frf_cc.port_b;
      nxt_f_funct_7 = frf_cc.f_funct_7;
      nxt_frm = frf_cc.f_frm_in;
    end
    endcase
  end
  
endmodule
