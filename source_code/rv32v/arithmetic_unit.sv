`include "vector_lane_if.vh"

module arithmetic_unit (
  input logic CLK, nRST,
  vector_lane_if.arithmetic_unit aif
);

  import rv32v_types_pkg::*;

  logic [31:0] vsdata1, vsdata2, vsdata3, other, sdata1, op3res, merge, comp, min, minu, max, maxu, mm, ext, f2z, f2s, f4z, f4s, f8z, f8s, finaldata2, finalresult, accumulator;
  logic [32:0] as_res, result;
  logic [6:0] shamt;
  logic vsdata1_msb, vsdata2_msb, sltu, slt, seq, sle, sleu, carryin;

  // SEW dependent signals
  assign vsdata1_msb = aif.sew == SEW8  ? vsdata1[7]:
                       aif.sew == SEW16 ? vsdata1[15]:
                       vsdata1[31];
  assign vsdata2_msb = aif.sew == SEW8  ? vsdata2[7]:
                       aif.sew == SEW16 ? vsdata2[15]:
                       vsdata2[31];
  assign shamnt      = aif.sew == SEW8 & !aif.win ? {4'd0, vsdata1[2:0]}:
                       (aif.sew == SEW8 & aif.win) || (aif.sew == SEW16 & !aif.win) ? {3'd0, vsdata1[3:0]}:
                       {2'b0, vsdata1[4:0]};
  assign f2z         = aif.sew == SEW8  ? {28'd0, vsdata2[3:0]}:
                       aif.sew == SEW16 ? {24'd0, vsdata2[7:0]}:
                       {16'd0, vsdata2[15:0]};
  assign f4z         = aif.sew == SEW8  ? {30'd0, vsdata2[1:0]}:
                       aif.sew == SEW16 ? {28'd0, vsdata2[3:0]}:
                       {24'd0, vsdata2[7:0]};
  assign f8z         = aif.sew == SEW8  ? {31'd0, vsdata2[0]}:
                       aif.sew == SEW16 ? {30'd0, vsdata2[1:0]}:
                       {28'd0, vsdata2[3:0]};
  assign f2s         = aif.sew == SEW8  ? {{28{vsdata2[3]}}, vsdata2[3:0]}:
                       aif.sew == SEW16 ? {{24{vsdata2[7]}}, vsdata2[7:0]}:
                       {{16{vsdata2[15]}}, vsdata2[15:0]};
  assign f4s         = aif.sew == SEW8  ? {{30{vsdata2[1]}}, vsdata2[1:0]}:
                       aif.sew == SEW16 ? {{28{vsdata2[3]}}, vsdata2[3:0]}:
                       {{24{vsdata2[7]}}, vsdata2[7:0]};
  assign f8s         = aif.sew == SEW8  ? {{31{vsdata2[0]}}, vsdata2[0]}:
                       aif.sew == SEW16 ? {{30{vsdata2[1]}}, vsdata2[1:0]}:
                       {{28{vsdata2[3]}}, vsdata2[3:0]};
  assign finaldata2  = aif.sew == SEW8 & aif.win & aif.zext_w ? {24'd0, vsdata2[7:0]} :
                       aif.sew == SEW8 & aif.win & !aif.zext_w ? {{24{vsdata2[7]}}, vsdata2[7:0]} :
                       aif.sew == SEW16 & aif.win & aif.zext_w ? {16'd0, vsdata2[15:0]} :
                       aif.sew == SEW16 & aif.win & !aif.zext_w ? {{16{vsdata2[15]}}, vsdata2[15:0]} :
                       aif.rev ? vsdata1 :
                       vsdata2;
  assign finalresult = aif.sew == SEW8 & aif.woutu ? {16'd0, result[15:0]} :
                       result[31:0];       

  assign vsdata1 = (aif.reduction_ena & (aif.index != 0) & (aif.index != 1)) ? accumulator : aif.vs1_data;
  assign vsdata2 = aif.vs2_data;
  assign vsdata3 = aif.vs3_data;
  assign sdata1  = aif.rev ? vsdata2 : vsdata1;
  //assign sdata2  = aif.rev ? vsdata1 : vsdata2;
  assign carryin = aif.carryin_ena ? aif.mask : 0;
  assign as_res  = aif.adc_sbc ? result + carryin : result - carryin;
  assign op3res  = aif.carry_borrow_ena ? {31'd0, as_res[32]} : as_res[31:0];
  assign merge   = aif.mask ? vsdata1 : vsdata2;
  assign sltu    = vsdata2 < vsdata1;
  assign slt     = vsdata1_msb & !vsdata2_msb ? 1:
                   !vsdata1_msb & vsdata2_msb ? 0:
                   sltu;
  assign seq     = vsdata1 == vsdata2;
  assign sleu    = sltu || seq;
  assign sle     = slt || seq;
  assign min     = slt ? vsdata2 : vsdata1;
  assign minu    = sltu ? vsdata2 : vsdata1;
  assign max     = slt ? vsdata1 : vsdata2;
  assign maxu    = sltu ? vsdata1 : vsdata2; 
 
  // Reduction Unit
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      accumulator <= '0;
    end else if (aif.reduction_ena) begin
      accumulator <= result[31:0];
    end
  end

  // Extension instr ALU
  always_comb begin 
    case (aif.ext_type)
      F2Z   : ext = f2z;
      F2S   : ext = f2s;
      F4Z   : ext = f4z;
      F4S   : ext = f4s;
      F8Z   : ext = f8z;
      F8S   : ext = f8s;
      default : ext = '0;
    endcase
  end             

  // Comparison instr ALU
  always_comb begin 
    case (aif.comp_type)
      SEQ   : comp = seq;
      SNE   : comp = seq == 0;
      SLTU  : comp = {31'd0, sltu};
      SLT   : comp = {31'd0, slt};
      SLEU  : comp = sleu;
      SLE   : comp = sle;
      SGTU  : comp = sleu == 0;
      SGT   : comp = sle == 0;
      default : comp = '0;
    endcase
  end

  // Comparison min/max ALU
  always_comb begin 
    case (aif.minmax_type)
      MIN  : mm = min;
      MINU : mm = minu;
      MAX  : mm = max;
      MAXU : mm = maxu;
      default : mm = '0;
    endcase
  end

  // Main ALU
  always_comb begin 
    case (aif.aluop)
      ALU_SLL   : result = vsdata2 << shamnt;
      ALU_SRL   : result = vsdata2 >> shamnt;
      ALU_SRA   : result = $signed(vsdata2) >>> shamnt;
      ALU_ADD   : result = finaldata2 + vsdata1;
      ALU_SUB   : result = finaldata2 - sdata1;
      ALU_AND   : result = vsdata2 & vsdata1;
      ALU_OR    : result = vsdata2 | vsdata1;
      ALU_XOR   : result = vsdata2 ^ vsdata1;
      ALU_COMP  : result = comp;
      ALU_MERGE : result = merge;
      ALU_MOVE  : result = vsdata1;
      ALU_MM    : result = mm;
      default   : result = '0;
    endcase
  end

  // Output Sel
  always_comb begin 
    case (aif.result_type)
      NORMAL    : aif.wdata_a = finalresult;
      A_S       : aif.wdata_a = op3res;
      MUL       : aif.wdata_a = 0;
      DIV       : aif.wdata_a = 0;
      REM       : aif.wdata_a = 0;
      default   : aif.wdata_a = other;
    endcase
  end



endmodule
