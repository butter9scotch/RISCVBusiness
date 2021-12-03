/*
*   Copyright 2016 Purdue University
*   
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*   
*       http://www.apache.org/licenses/LICENSE-2.0
*   
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*
*
*   Filename:     arithmetic_unit.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 10/15/2021
*   Description:  ALU
*/

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
  // assign aif.win = 0; //TODO: CHANGE THIS
  // assign aif.woutu = 0; //TODO: CHANGE THIS
  // assign aif.zext_w = 0; //TODO: CHANGE THIS
  

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


                       //aif.zext_w = zero extend source
                       //aif.vd_widen = widen vd
                       //aif.win = widen vs2

                       //SEW 8, widening NOT widening vs2
  assign finaldata2  = aif.sew == SEW8 & aif.vd_widen & ~aif.win & aif.zext_w  ? {24'd0, vsdata2[7:0]} :
                       aif.sew == SEW8 & aif.vd_widen & ~aif.win & !aif.zext_w ? {{24{vsdata2[7]}}, vsdata2[7:0]} :

                       //SEW 8, widening AND widening vs2
                       aif.sew == SEW8 & aif.vd_widen & aif.win & !aif.zext_w   ? {16'd0, vsdata2[15:0]} :
                       aif.sew == SEW8 & aif.vd_widen & aif.win & !aif.zext_w   ? {{16{vsdata2[15]}}, vsdata2[15:0]} :
                       
                       //SEW 16, widening NOT widening vs2
                       aif.sew == SEW16 & aif.vd_widen & ~aif.win & aif.zext_w  ? {16'd0, vsdata2[15:0]} :
                       aif.sew == SEW16 & aif.vd_widen & ~aif.win & !aif.zext_w ? {{16{vsdata2[15]}}, vsdata2[15:0]} :

                       //SEW 16, widening AND widening vs2 -- this is just normal
                       aif.rev ? vsdata1 :
                       vsdata2;
  
  assign finalresult = aif.sew == SEW8 & aif.woutu ? {16'd0, result[15:0]} :
                       result[31:0]; 


  // if (aif.vd_widen & !aif.zext_w) begin
  //   if (aif.sew == SEW8) begin
  //     finalresult = {16'd0, {8{result[7]}}, result[7:0]};
  //   end else if (aif.sew == SEW16) begin
  //     finalresult = {{16{result[15]}}, result[15:0]};
  //   end else begin
  //     finalresult = result[31:0];
  //   end
  // end

  assign vsdata1 = (aif.reduction_ena & (aif.index != 0) & (aif.index != 1)) ? accumulator : 
                    (aif.sew == SEW8 & aif.vd_widen & !aif.zext_w )  ? {{24{aif.vs1_data[7]}}, aif.vs1_data[7:0]}  : 
                    (aif.sew == SEW16 & aif.vd_widen & !aif.zext_w ) ? {{16{aif.vs1_data[15]}}, aif.vs1_data[15:0]} : 
                    aif.vs1_data;
  
  assign sdata1  = aif.rev ? vsdata2 : vsdata1;


  assign vsdata2 = aif.vs2_data;
  assign vsdata3 = aif.vs3_data;
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
      VSEQ   : comp = seq;
      VSNE   : comp = seq == 0;
      VSLTU  : comp = {31'd0, sltu};
      VSLT   : comp = {31'd0, slt};
      VSLEU  : comp = sleu;
      VSLE   : comp = sle;
      VSGTU  : comp = sleu == 0;
      VSGT   : comp = sle == 0;
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
      VALU_SLL   : result = vsdata2 << shamnt;
      VALU_SRL   : result = vsdata2 >> shamnt;
      VALU_SRA   : result = $signed(vsdata2) >>> shamnt;
      VALU_ADD   : result = finaldata2 + vsdata1;
      VALU_SUB   : result = finaldata2 - sdata1;
      VALU_AND   : result = vsdata2 & vsdata1;
      VALU_OR    : result = vsdata2 | vsdata1;
      VALU_XOR   : result = vsdata2 ^ vsdata1;
      VALU_COMP  : result = comp;
      VALU_MERGE : result = merge;
      VALU_MOVE  : result = vsdata1;
      VALU_MM    : result = mm;
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

  assign aif.exception_a = 0; //TODO

endmodule
