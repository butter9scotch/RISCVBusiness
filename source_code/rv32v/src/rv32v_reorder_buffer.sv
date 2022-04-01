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
*   Filename:     rv32v_reorder_buffer.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 1/30/2022
*   Description:  Reorder Buffer to support OoO completion within vector unit
*/

`include "rv32v_reorder_buffer_if.vh"
`include "entry_modifier_if.vh"

module rv32v_reorder_buffer # (
  parameter NUM_ENTRY = 16,
  parameter DATA_WIDTH = 128
)
(
  input CLK, nRST,
  rv32v_reorder_buffer_if.rob rob_if
);
  import rv32i_types_pkg::*;

  typedef struct packed {
    logic [DATA_WIDTH-1:0] data;
    logic [4:0] vd;
    logic [15:0] wen;
    logic valid;
    logic exception;
    logic [4:0] exception_index;
    logic single_bit_write;
    logic commit_ack;
    sew_t sew;
  } rob_entry;

  logic [$clog2(NUM_ENTRY):0] head, tail, next_head, next_tail;
  rob_entry rob [0:NUM_ENTRY-1]; 
  rob_entry next_rob [0:NUM_ENTRY-1]; 
  sew_t head_sew;
  logic [VL_WIDTH:0] vl_reg;
  logic [$clog2(NUM_ENTRY)-1:0] index_a, index_mu, index_du, index_m, index_p, index_ls;
  logic [4:0] head_exception_index, excep_index_off32, excep_index_off16, excep_index_off8, excep_index_final;
  logic [4:0] vd_a, vd_mu, vd_du, vd_m, vd_p, vd_ls;
  logic [3:0] vd_wen_offset_a, vd_wen_offset_mu, vd_wen_offset_du, vd_wen_offset_m, vd_wen_offset_p, vd_wen_offset_ls;
  logic [6:0] vd_outer_offset_a, vd_outer_offset_mu, vd_outer_offset_du, vd_outer_offset_m, vd_outer_offset_p, vd_outer_offset_ls;
  logic reached_max_a, reached_max_mu, reached_max_du, reached_max_m, reached_max_p, reached_max_ls;
  logic filled_one_entry_a, filled_one_entry_mu, filled_one_entry_du, filled_one_entry_m, filled_one_entry_p, filled_one_entry_ls;
  logic flush;
  integer i;

  entry_modifier_if a_em_if();
  entry_modifier_if mu_em_if();
  entry_modifier_if du_em_if();
  entry_modifier_if m_em_if();
  entry_modifier_if p_em_if();
  entry_modifier_if ls_em_if();

  entry_modifier a_em (a_em_if);
  entry_modifier mu_em (mu_em_if);
  entry_modifier du_em (du_em_if);
  entry_modifier m_em (m_em_if);
  entry_modifier p_em (p_em_if);
  entry_modifier ls_em (ls_em_if);

  assign a_em_if.woffset  = rob_if.woffset_a;
  assign a_em_if.index    = rob_if.index_a;
  assign a_em_if.vd       = rob_if.vd_a;
  assign a_em_if.sew      = rob_if.sew_a;
  assign mu_em_if.woffset = rob_if.woffset_mu;
  assign mu_em_if.index   = rob_if.index_mu;
  assign mu_em_if.vd      = rob_if.vd_mu;
  assign mu_em_if.sew     = rob_if.sew_mu;
  assign du_em_if.woffset = rob_if.woffset_du;
  assign du_em_if.index   = rob_if.index_du;
  assign du_em_if.vd      = rob_if.vd_du;
  assign du_em_if.sew     = rob_if.sew_du;
  assign m_em_if.woffset  = rob_if.woffset_m;
  assign m_em_if.index    = rob_if.index_m;
  assign m_em_if.vd       = rob_if.vd_m;
  assign m_em_if.sew      = rob_if.sew_m;
  assign p_em_if.woffset  = rob_if.woffset_p;
  assign p_em_if.index    = rob_if.index_p;
  assign p_em_if.vd       = rob_if.vd_p;
  assign p_em_if.sew      = rob_if.sew_p;
  assign ls_em_if.woffset = rob_if.woffset_ls;
  assign ls_em_if.index   = rob_if.index_ls;
  assign ls_em_if.vd      = rob_if.vd_ls;
  assign ls_em_if.sew     = rob_if.sew_ls;

  assign flush                = rob_if.branch_mispredict | rob_if.scalar_exception;
  assign head_exception_index = rob[head].exception_index;
  assign head_sew             = rob[head].sew;
  assign excep_index_off32    = head_exception_index[1:0] << 2;
  assign excep_index_off16    = head_exception_index[2:0] << 1;
  assign excep_index_off8     = head_exception_index[3:0];

  assign rob_if.cur_tail    = tail[$clog2(NUM_ENTRY)-1:0]; 
  assign rob_if.full        = head[$clog2(NUM_ENTRY)-1:0] == tail[$clog2(NUM_ENTRY)-1:0] && head[$clog2(NUM_ENTRY)] != tail[$clog2(NUM_ENTRY)]; 
  assign rob_if.vreg_wen    = rob[head].valid & rob_if.commit_ena;
  assign rob_if.commit_done = rob_if.vreg_wen & rob[head].commit_ack;
  assign rob_if.vd_final    = rob[head].vd;
  assign rob_if.wen_final   = rob_if.rv32v_exception ? (rob[head].wen & ~(16'hffff << excep_index_final)) : rob[head].wen;
  assign rob_if.wdata_final = rob[head].data;
  assign rob_if.single_wen  = rob[head].single_bit_write;
  assign rob_if.single_wen_vl   = vl_reg;
  assign rob_if.rv32v_exception = rob[head].exception & rob_if.commit_ena;

  assign reached_max_a  = (rob_if.woffset_a == rob_if.vl_a - 1) || (rob_if.woffset_a == rob_if.vl_a - 2);
  assign reached_max_mu = (rob_if.woffset_mu == rob_if.vl_mu - 1) || (rob_if.woffset_mu == rob_if.vl_mu - 2);
  assign reached_max_du = (rob_if.woffset_du == rob_if.vl_du - 1) || (rob_if.woffset_du == rob_if.vl_du - 2);
  assign reached_max_m  = (rob_if.woffset_m == rob_if.vl_m - 1) || (rob_if.woffset_m == rob_if.vl_m - 2);
  assign reached_max_p  = (rob_if.woffset_p == rob_if.vl_p - 1) || (rob_if.woffset_p == rob_if.vl_p - 2);
  assign reached_max_ls = (rob_if.woffset_ls == rob_if.vl_ls - 1) || (rob_if.woffset_ls == rob_if.vl_ls - 2);

  // HEAD AND TAIL POINTER LOGIC
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      head <= '0;
      tail <= '0;
    end else begin
      head <= next_head;
      tail <= next_tail;
    end
  end 

  always_comb begin
    next_head = head;
    if (flush) begin
      next_head = 0;
    end else if (rob_if.vreg_wen) begin
      next_head = head + 1;
    end
  end

  always_comb begin
    next_tail = tail;
    if (flush) begin
        next_tail = 0;
    end else if (rob_if.alloc_ena & ~rob_if.full) begin
      if (rob_if.single_bit_op) begin
        next_tail = tail + 1;
      end else begin
        case (rob_if.lmul) 
          LMUL1, LMULHALF, LMULFOURTH, LMULEIGHTH: next_tail = tail + 1;
          LMUL2: next_tail = tail + 2;
          LMUL4: next_tail = tail + 4;
          LMUL8: next_tail = tail + 8;
          default: next_tail = tail;
        endcase
      end
    end
  end

  // ROB LOGIC
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      for (i = 0; i < NUM_ENTRY; i++) begin
        rob[i] <= '0;
      end
    end else if (flush) begin
      for (i = 0; i < NUM_ENTRY; i++) begin
        rob[i] <= '0;
      end
    end else begin
      for (i = 0; i < NUM_ENTRY; i++) begin
        rob[i] <= next_rob[i];
      end
    end
  end 

  // Modify exception index
  always_comb begin
    case(head_sew)
      SEW32: begin
        excep_index_final  = excep_index_off32;
      end
      SEW16: begin 
        excep_index_final  = excep_index_off16;
      end
      default: begin
        excep_index_final  = excep_index_off8;
      end 
    endcase 
  end

  // Latch VL for single bit write (avoid adding extra entry in rob)
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      vl_reg <= '0;
    end else if (rob_if.ready_a & rob_if.single_bit_write) begin
      vl_reg <= rob_if.vl_a;
    end
  end 

  always_comb begin
    // Set default value
    next_rob = rob;
    // Clear head entry when committed
    if (rob_if.vreg_wen) begin
      next_rob[head] = '0;
    end
    // Next state for arithemtic unit result
    if (rob_if.ready_a) begin
      next_rob[rob_if.index_a].sew = rob_if.sew_a; 
      next_rob[a_em_if.final_index].exception = rob[a_em_if.final_index].exception | rob_if.exception_a;
      if (rob_if.exception_a & ~rob[a_em_if.final_index].exception) begin
        next_rob[a_em_if.final_index].exception_index = rob_if.exception_index_a;
      end else begin
        next_rob[a_em_if.final_index].exception_index = rob[a_em_if.final_index].exception_index;
      end
      if (rob_if.single_bit_write) begin
        next_rob[rob_if.index_a].single_bit_write = 1; 
        next_rob[rob_if.index_a].vd = rob_if.vd_a;
        next_rob[rob_if.index_a].data[rob_if.woffset_a+:2] = {rob_if.wdata_a[32], rob_if.wdata_a[0]};
        next_rob[rob_if.index_a].wen = '1; // TODO: Corner case: Masked single bit write. 
        next_rob[rob_if.index_a].valid = (rob_if.woffset_a == VLEN - 1) | (rob_if.woffset_a == VLEN - 2) | reached_max_a;
        next_rob[rob_if.index_a].commit_ack = reached_max_a;
      end else begin
        next_rob[a_em_if.final_index].single_bit_write = 0; 
        next_rob[a_em_if.final_index].sew = rob_if.sew_a;
        next_rob[a_em_if.final_index].vd = a_em_if.final_vd;
        next_rob[a_em_if.final_index].valid = a_em_if.filled_one_entry | reached_max_a;
        next_rob[a_em_if.final_index].commit_ack = reached_max_a;
        case(rob_if.sew_a)
          SEW32: begin
            next_rob[a_em_if.final_index].data[a_em_if.vd_outer_offset+:64] = rob_if.wdata_a;
            next_rob[a_em_if.final_index].wen[a_em_if.vd_wen_offset+:8] = {{4{rob_if.wen_a[1]}}, {4{rob_if.wen_a[0]}}};
          end
          SEW16: begin 
            next_rob[a_em_if.final_index].data[a_em_if.vd_outer_offset+:32] = {rob_if.wdata_a[47:32], rob_if.wdata_a[15:0]};
            next_rob[a_em_if.final_index].wen[a_em_if.vd_wen_offset+:4] = {{2{rob_if.wen_a[1]}}, {2{rob_if.wen_a[0]}}};
          end
          default: begin
            next_rob[a_em_if.final_index].data[a_em_if.vd_outer_offset+:16] = {rob_if.wdata_a[39:32], rob_if.wdata_a[7:0]};
            next_rob[a_em_if.final_index].wen[a_em_if.vd_wen_offset+:2] = rob_if.wen_a;
          end
        endcase
      end
    end
    // Next state for multiply unit result
    if (rob_if.ready_mu) begin
      next_rob[mu_em_if.final_index].single_bit_write = 0; 
      next_rob[mu_em_if.final_index].sew = rob_if.sew_mu;
      next_rob[mu_em_if.final_index].vd = mu_em_if.final_vd;
      next_rob[mu_em_if.final_index].valid = mu_em_if.filled_one_entry | reached_max_mu;
      next_rob[mu_em_if.final_index].exception = rob[mu_em_if.final_index].exception | rob_if.exception_mu;
      next_rob[mu_em_if.final_index].commit_ack = reached_max_mu;
      if (rob_if.exception_mu & ~rob[mu_em_if.final_index].exception) begin
        next_rob[mu_em_if.final_index].exception_index = rob_if.exception_index_mu;
      end else begin
        next_rob[mu_em_if.final_index].exception_index = rob[mu_em_if.final_index].exception_index;
      end
      case(rob_if.sew_mu)
        SEW32: begin
          next_rob[mu_em_if.final_index].data[mu_em_if.vd_outer_offset+:64] = rob_if.wdata_mu;
          next_rob[mu_em_if.final_index].wen[mu_em_if.vd_wen_offset+:8] = {{4{rob_if.wen_mu[1]}}, {4{rob_if.wen_mu[0]}}};
        end
        SEW16: begin 
          next_rob[mu_em_if.final_index].data[mu_em_if.vd_outer_offset+:32] = {rob_if.wdata_mu[47:32], rob_if.wdata_mu[15:0]};
          next_rob[mu_em_if.final_index].wen[mu_em_if.vd_wen_offset+:4] = {{2{rob_if.wen_mu[1]}}, {2{rob_if.wen_mu[0]}}};
        end
        default: begin
          next_rob[mu_em_if.final_index].data[mu_em_if.vd_outer_offset+:16] = {rob_if.wdata_mu[39:32], rob_if.wdata_mu[7:0]};
          next_rob[mu_em_if.final_index].wen[mu_em_if.vd_wen_offset+:2] = rob_if.wen_mu;
        end
      endcase
    end
    // Next state for divide unit result
    if (rob_if.ready_du) begin
      next_rob[du_em_if.final_index].single_bit_write = 0; 
      next_rob[du_em_if.final_index].sew = rob_if.sew_du;
      next_rob[du_em_if.final_index].vd = du_em_if.final_vd;
      next_rob[du_em_if.final_index].valid = du_em_if.filled_one_entry | reached_max_du;
      next_rob[du_em_if.final_index].commit_ack = reached_max_du;
      next_rob[du_em_if.final_index].exception = rob[du_em_if.final_index].exception | rob_if.exception_du;
      if (rob_if.exception_du & ~rob[du_em_if.final_index].exception) begin
        next_rob[du_em_if.final_index].exception_index = rob_if.exception_index_du;
      end else begin
        next_rob[du_em_if.final_index].exception_index = rob[du_em_if.final_index].exception_index;
      end
      case(rob_if.sew_du)
        SEW32: begin
          next_rob[du_em_if.final_index].data[du_em_if.vd_outer_offset+:64] = rob_if.wdata_du;
          next_rob[du_em_if.final_index].wen[du_em_if.vd_wen_offset+:8] = {{4{rob_if.wen_du[1]}}, {4{rob_if.wen_du[0]}}};
        end
        SEW16: begin 
          next_rob[du_em_if.final_index].data[du_em_if.vd_outer_offset+:32] = {rob_if.wdata_du[47:32], rob_if.wdata_du[15:0]};
          next_rob[du_em_if.final_index].wen[du_em_if.vd_wen_offset+:4] = {{2{rob_if.wen_du[1]}}, {2{rob_if.wen_du[0]}}};
        end
        default: begin
          next_rob[du_em_if.final_index].data[du_em_if.vd_outer_offset+:16] = {rob_if.wdata_du[39:32], rob_if.wdata_du[7:0]};
          next_rob[du_em_if.final_index].wen[du_em_if.vd_wen_offset+:2] = rob_if.wen_du;
        end
      endcase
    end
    // Next state for mask unit result
    if (rob_if.ready_m) begin
      next_rob[m_em_if.final_index].single_bit_write = 0; 
      next_rob[m_em_if.final_index].sew = rob_if.sew_m;
      next_rob[m_em_if.final_index].vd = m_em_if.final_vd;
      next_rob[m_em_if.final_index].valid = m_em_if.filled_one_entry | reached_max_m;
      next_rob[m_em_if.final_index].commit_ack = reached_max_m;
      next_rob[m_em_if.final_index].exception = rob[m_em_if.final_index].exception | rob_if.exception_m;
      if (rob_if.exception_m & ~rob[m_em_if.final_index].exception) begin
        next_rob[m_em_if.final_index].exception_index = rob_if.exception_index_m;
      end else begin
        next_rob[m_em_if.final_index].exception_index = rob[index_m].exception_index;
      end
      case(rob_if.sew_m)
        SEW32: begin
          next_rob[m_em_if.final_index].data[m_em_if.vd_outer_offset+:64] = rob_if.wdata_m;
          next_rob[m_em_if.final_index].wen[m_em_if.vd_wen_offset+:8] = {{4{rob_if.wen_m[1]}}, {4{rob_if.wen_m[0]}}};
        end
        SEW16: begin 
          next_rob[m_em_if.final_index].data[m_em_if.vd_outer_offset+:32] = {rob_if.wdata_m[47:32], rob_if.wdata_m[15:0]};
          next_rob[m_em_if.final_index].wen[m_em_if.vd_wen_offset+:4] = {{2{rob_if.wen_m[1]}}, {2{rob_if.wen_m[0]}}};
        end
        default: begin
          next_rob[m_em_if.final_index].data[m_em_if.vd_outer_offset+:16] = {rob_if.wdata_m[39:32], rob_if.wdata_m[7:0]};
          next_rob[m_em_if.final_index].wen[m_em_if.vd_wen_offset+:2] = rob_if.wen_m;
        end
      endcase
    end
    // Next state for permutation unit result
    if (rob_if.ready_p) begin
      next_rob[p_em_if.final_index].single_bit_write = 0; 
      next_rob[p_em_if.final_index].sew = rob_if.sew_p;
      next_rob[p_em_if.final_index].vd = p_em_if.final_vd;
      next_rob[p_em_if.final_index].valid = p_em_if.filled_one_entry | reached_max_p;
      next_rob[p_em_if.final_index].commit_ack = reached_max_p;
      next_rob[p_em_if.final_index].exception = rob[p_em_if.final_index].exception | rob_if.exception_p;
      if (rob_if.exception_p & ~rob[p_em_if.final_index].exception) begin
        next_rob[p_em_if.final_index].exception_index = rob_if.exception_index_p;
      end else begin
        next_rob[p_em_if.final_index].exception_index = rob[p_em_if.final_index].exception_index;
      end
      case(rob_if.sew_p)
        SEW32: begin
          next_rob[p_em_if.final_index].data[p_em_if.vd_outer_offset+:64] = rob_if.wdata_p;
          next_rob[p_em_if.final_index].wen[p_em_if.vd_wen_offset+:8] = {{4{rob_if.wen_p[1]}}, {4{rob_if.wen_p[0]}}};
        end
        SEW16: begin 
          next_rob[p_em_if.final_index].data[p_em_if.vd_outer_offset+:32] = {rob_if.wdata_p[47:32], rob_if.wdata_p[15:0]};
          next_rob[p_em_if.final_index].wen[p_em_if.vd_wen_offset+:4] = {{2{rob_if.wen_p[1]}}, {2{rob_if.wen_p[0]}}};
        end
        default: begin
          next_rob[p_em_if.final_index].data[p_em_if.vd_outer_offset+:16] = {rob_if.wdata_p[39:32], rob_if.wdata_p[7:0]};
          next_rob[p_em_if.final_index].wen[p_em_if.vd_wen_offset+:2] = rob_if.wen_p;
        end
      endcase
    end
    // Next state for load store unit result
    if (rob_if.ready_ls) begin
      next_rob[ls_em_if.final_index].single_bit_write = 0; 
      next_rob[ls_em_if.final_index].sew = rob_if.sew_ls;
      next_rob[ls_em_if.final_index].vd = ls_em_if.final_vd;
      next_rob[ls_em_if.final_index].valid = ls_em_if.filled_one_entry | reached_max_ls;
      next_rob[ls_em_if.final_index].commit_ack = reached_max_ls;
      next_rob[ls_em_if.final_index].exception = rob[ls_em_if.final_index].exception | rob_if.exception_ls;
      if (rob_if.exception_ls & ~rob[ls_em_if.final_index].exception) begin
        next_rob[ls_em_if.final_index].exception_index = rob_if.exception_index_ls;
      end else begin
        next_rob[ls_em_if.final_index].exception_index = rob[ls_em_if.final_index].exception_index;
      end
      case(rob_if.sew_ls)
        SEW32: begin
          next_rob[ls_em_if.final_index].data[ls_em_if.vd_outer_offset+:64] = rob_if.wdata_ls;
          next_rob[ls_em_if.final_index].wen[ls_em_if.vd_wen_offset+:8] = {{4{rob_if.wen_ls[1]}}, {4{rob_if.wen_ls[0]}}};
        end
        SEW16: begin 
          next_rob[ls_em_if.final_index].data[ls_em_if.vd_outer_offset+:32] = {rob_if.wdata_ls[47:32], rob_if.wdata_ls[15:0]};
          next_rob[ls_em_if.final_index].wen[ls_em_if.vd_wen_offset+:4] = {{2{rob_if.wen_ls[1]}}, {2{rob_if.wen_ls[0]}}};
        end
        default: begin
          next_rob[ls_em_if.final_index].data[ls_em_if.vd_outer_offset+:16] = {rob_if.wdata_ls[39:32], rob_if.wdata_ls[7:0]};
          next_rob[ls_em_if.final_index].wen[ls_em_if.vd_wen_offset+:2] = rob_if.wen_ls;
        end
      endcase
    end
  end

endmodule
