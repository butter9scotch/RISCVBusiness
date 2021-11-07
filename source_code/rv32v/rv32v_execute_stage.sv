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
*   Filename:     rv32v_execute_stage.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 10/30/2021
*   Description:  RV32V Execute Stage
*/

`include "rv32v_execute_memory_if.vh"
`include "rv32v_decode_execute_if.vh"
`include "vector_lane_if.vh"

module rv32v_execute_stage (
  input logic CLK, nRST,
  rv32v_hazard_unit_if.execute hu_if,
  rv32v_decode_execute_if.execute decode_execute_if,
  rv32v_execute_memory_if.execute execute_memory_if,
  output logic rd_WEN,
  output logic [4:0] rd_sel,
  output logic [31:0] rd_data
);

  import rv32v_types_pkg::*;

  logic [31:0] aluresult0, aluresult1, portb0, base_addr, addr_buffer, coherence_res;
  logic ls;

  vector_lane_if vif0 ();
  vector_lane_if vif1 ();

  vector_lane V0 (CLK, nRST, vif0);
  vector_lane V1 (CLK, nRST, vif1);

  assign portb0    = decode_execute_if.stride_type ? decode_execute_if.stride_val : 4;
  assign base_addr = decode_execute_if.xs1;
  assign rd_WEN    = decode_execute_if.rd_WEN | decode_execute_if.config_type;
  assign rd_sel    = decode_execute_if.rd_sel;
  assign rd_data   = decode_execute_if.config_type ? decode_execute_if.vl : coherence_res; //TODO: Add coherence unit signal

  // Data select 
  assign vif0.vs3_data = decode_execute_if.vs3_lane0; // Needed for mul-add instr
  assign vif1.vs3_data = decode_execute_if.vs3_lane1; // Needed for mul-add instr
  always_comb begin
    case(decode_execute_if.rs1_type)
      V:
      begin
        vif0.vs1_data = decode_execute_if.vs1_lane0;
        vif1.vs1_data = decode_execute_if.vs1_lane1;
      end
      I:
      begin
        vif0.vs1_data = decode_execute_if.imm;
        vif1.vs1_data = decode_execute_if.imm;
      end
      X:
      begin
        vif0.vs1_data = decode_execute_if.xs1;
        vif1.vs1_data = decode_execute_if.xs1;
      end
      default:
      begin
        vif0.vs1_data = '0;
        vif1.vs1_data = '0;
      end 
    endcase
  end

  always_comb begin
    case(decode_execute_if.rs2_type)
      V:
      begin
        vif0.vs2_data = decode_execute_if.vs2_lane0;
        vif1.vs2_data = decode_execute_if.vs2_lane1;
      end
      I:
      begin
        vif0.vs2_data = decode_execute_if.imm;
        vif1.vs2_data = decode_execute_if.imm;
      end
      X:
      begin
        vif0.vs2_data = decode_execute_if.xs2;
        vif1.vs2_data = decode_execute_if.xs2;
      end
      default:
      begin
        vif0.vs2_data = '0;
        vif1.vs2_data = '0;
      end 
    endcase
  end

  // Vector Lane 0
  //assign vif0.stride          = decode_execute_if.stride;
  assign vif0.fu_type         = decode_execute_if.fu_type;
  //assign vif0.load_store_type = decode_execute_if.load_store_type;
  assign vif0.result_type     = decode_execute_if.result_type;
  assign vif0.offset          = decode_execute_if.woffset0;
  assign vif0.aluop           = decode_execute_if.aluop;
  assign vif0.mask            = decode_execute_if.mask0;
  assign vif0.reduction_ena   = decode_execute_if.reduction_ena;
  assign vif0.is_signed       = decode_execute_if.is_signed;
  assign vif0.porta0          = addr_buffer;
  assign vif0.porta1          = base_addr;
  assign vif0.portb0          = portb0;
  assign vif0.portb1          = decode_execute_if.vs2_lane0;
  assign vif0.porta_sel       = decode_execute_if.ls_idx | (decode_execute_if.woffset0 == 0);
  assign vif0.portb_sel       = decode_execute_if.ls_idx;
  assign vif0.is_signed       = decode_execute_if.is_signed;
  assign vif0.multiply_type   = decode_execute_if.multiply_type;
  assign vif0.multiply_pos_neg= decode_execute_if.multiply_pos_neg;
  assign vif0.mul_widen_ena   = decode_execute_if.mul_widen_ena;
  assign vif0.high_low        = decode_execute_if.high_low;
  assign vif0.div_type        = decode_execute_if.div_type;
  assign vif0.is_signed_div   = decode_execute_if.is_signed_div;

  // Vector Lane 1
  //assign vif1.stride          = decode_execute_if.stride;
  assign vif1.fu_type         = decode_execute_if.fu_type;
  //assign vif1.load_store_type = decode_execute_if.load_store_type;
  assign vif1.result_type     = decode_execute_if.result_type;
  assign vif1.offset          = decode_execute_if.woffset1;
  assign vif1.aluop           = decode_execute_if.aluop;
  assign vif1.mask            = decode_execute_if.mask1;
  assign vif1.reduction_ena   = decode_execute_if.reduction_ena;
  assign vif1.is_signed       = decode_execute_if.is_signed;
  assign vif1.porta0          = vif0.out_addr;
  assign vif1.porta1          = base_addr;
  assign vif1.portb0          = portb0;
  assign vif1.portb1          = decode_execute_if.vs2_lane1;
  assign vif1.porta_sel       = decode_execute_if.ls_idx;
  assign vif1.portb_sel       = decode_execute_if.ls_idx;
  assign vif1.is_signed       = decode_execute_if.is_signed;
  assign vif1.multiply_type   = decode_execute_if.multiply_type;
  assign vif1.multiply_pos_neg= decode_execute_if.multiply_pos_neg;
  assign vif1.mul_widen_ena   = decode_execute_if.mul_widen_ena;
  assign vif1.high_low        = decode_execute_if.high_low;
  assign vif1.div_type        = decode_execute_if.div_type;
  assign vif1.is_signed_div   = decode_execute_if.is_signed_div;

  // Address Buffer
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      addr_buffer <= '0;
    end else if (!hu_if.stall_ex) begin
      addr_buffer <= vif1.out_addr;
    end
  end

  // Pipeline Latch
  assign ls = decode_execute_if.load | decode_execute_if.store;
  assign aluresult0 = ls ? vif0.in_addr : vif0.lane_result;
  assign aluresult1 = ls ? vif0.out_addr : vif1.lane_result;
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      execute_memory_if.load        <= '0;
      execute_memory_if.store       <= '0;
      execute_memory_if.storedata0  <= '0;
      execute_memory_if.storedata1  <= '0;
      execute_memory_if.aluresult0  <= '0;
      execute_memory_if.aluresult1  <= '0;
      execute_memory_if.wen0        <= '0;
      execute_memory_if.wen1        <= '0;
      execute_memory_if.woffset0    <= '0;
      execute_memory_if.woffset1    <= '0;
      execute_memory_if.config_type <= '0;
      execute_memory_if.vl          <= '0;
      execute_memory_if.vtype       <= '0;
    end else if (hu_if.flush_ex) begin
      execute_memory_if.load        <= '0;
      execute_memory_if.store       <= '0;
      execute_memory_if.storedata0  <= '0;
      execute_memory_if.storedata1  <= '0;
      execute_memory_if.aluresult0  <= '0;
      execute_memory_if.aluresult1  <= '0;
      execute_memory_if.wen0        <= '0;
      execute_memory_if.wen1        <= '0;
      execute_memory_if.woffset0    <= '0;
      execute_memory_if.woffset1    <= '0;
      execute_memory_if.config_type <= '0;
      execute_memory_if.vl          <= '0;
      execute_memory_if.vtype       <= '0;
    end else if (!hu_if.stall_ex) begin
      execute_memory_if.load        <= decode_execute_if.load;
      execute_memory_if.store       <= decode_execute_if.store;
      execute_memory_if.storedata0  <= decode_execute_if.storedata0;
      execute_memory_if.storedata1  <= decode_execute_if.storedata1;
      execute_memory_if.aluresult0  <= aluresult0;
      execute_memory_if.aluresult1  <= aluresult1;
      execute_memory_if.wen0        <= decode_execute_if.wen0;
      execute_memory_if.wen1        <= decode_execute_if.wen1;
      execute_memory_if.woffset0    <= decode_execute_if.woffset0;
      execute_memory_if.woffset1    <= decode_execute_if.woffset1;
      execute_memory_if.config_type <= decode_execute_if.config_type;
      execute_memory_if.vl          <= decode_execute_if.vl;
      execute_memory_if.vtype       <= decode_execute_if.vtype;
    end
  end

endmodule
