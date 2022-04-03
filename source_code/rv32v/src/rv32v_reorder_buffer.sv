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
  rv32v_reorder_buffer_if.rob rob_if,
  rv32v_reg_file_if.rob rfv_if
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
  // logic [$clog2(NUM_ENTRY)-1:0] index, index_mu, index_du, index_m, index_p, index_ls;
  logic [4:0] head_exception_index, excep_index_off32, excep_index_off16, excep_index_off8, excep_index_final;
  logic [4:0] vd_a, vd_mu, vd_du, vd_m, vd_p, vd_ls;
  logic [3:0] vd_wen_offset_a, vd_wen_offset_mu, vd_wen_offset_du, vd_wen_offset_m, vd_wen_offset_p, vd_wen_offset_ls;
  logic [6:0] vd_outer_offset_a, vd_outer_offset_mu, vd_outer_offset_du, vd_outer_offset_m, vd_outer_offset_p, vd_outer_offset_ls;
  logic reached_max_a, reached_max_mu, reached_max_du, reached_max_m, reached_max_p, reached_max_ls;
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

  assign a_em_if.woffset  = rob_if.a_sigs.woffset;
  assign a_em_if.index    = rob_if.a_sigs.index;
  assign a_em_if.vd       = rob_if.a_sigs.vd;
  assign a_em_if.sew      = rob_if.a_sigs.sew;
  assign mu_em_if.woffset = rob_if.mu_sigs.woffset;
  assign mu_em_if.index   = rob_if.mu_sigs.index;
  assign mu_em_if.vd      = rob_if.mu_sigs.vd;
  assign mu_em_if.sew     = rob_if.mu_sigs.sew;
  assign du_em_if.woffset = rob_if.du_sigs.woffset;
  assign du_em_if.index   = rob_if.du_sigs.index;
  assign du_em_if.vd      = rob_if.du_sigs.vd;
  assign du_em_if.sew     = rob_if.du_sigs.sew;
  assign m_em_if.woffset  = rob_if.m_sigs.woffset;
  assign m_em_if.index    = rob_if.m_sigs.index;
  assign m_em_if.vd       = rob_if.m_sigs.vd;
  assign m_em_if.sew      = rob_if.m_sigs.sew;
  assign p_em_if.woffset  = rob_if.p_sigs.woffset;
  assign p_em_if.index    = rob_if.p_sigs.index;
  assign p_em_if.vd       = rob_if.p_sigs.vd;
  assign p_em_if.sew      = rob_if.p_sigs.sew;
  assign ls_em_if.woffset = rob_if.ls_sigs.woffset;
  assign ls_em_if.index   = rob_if.ls_sigs.index;
  assign ls_em_if.vd      = rob_if.ls_sigs.vd;
  assign ls_em_if.sew     = rob_if.ls_sigs.sew;

  assign flush                = rob_if.branch_mispredict | rob_if.scalar_exception;
  assign head_exception_index = rob[head].exception_index;
  assign head_sew             = rob[head].sew;
  assign excep_index_off32    = head_exception_index[1:0] << 2;
  assign excep_index_off16    = head_exception_index[2:0] << 1;
  assign excep_index_off8     = head_exception_index[3:0];

  logic counter_done_ff1;
  always_ff @(posedge CLK, negedge nRST) begin : DELAY_DONE_SIGNAL
    if (~nRST) begin
      counter_done_ff1 <= 0;
    end else begin
      counter_done_ff1 <= rob_if.counter_done;
    end
  end

  assign rob_if.cur_tail    = tail[$clog2(NUM_ENTRY)-1:0]; 
  assign rob_if.full        = head[$clog2(NUM_ENTRY)-1:0] == tail[$clog2(NUM_ENTRY)-1:0] && head[$clog2(NUM_ENTRY)] != tail[$clog2(NUM_ENTRY)]; 
  assign rob_if.vreg_wen    = rob[head].valid & rob_if.commit_ena;
  assign rob_if.commit_done = rob_if.vreg_wen & rob[head].commit_ack ;
  assign rob_if.v_done      = rob_if.rd_wen ? counter_done_ff1 :rob[head].commit_ack;
  assign rob_if.vd_final    = rob[head].vd;
  assign rob_if.wen_final   = rob_if.v_exception ? (rob[head].wen & ~(16'hffff << excep_index_final)) : rob[head].wen;
  assign rob_if.wdata_final = rob[head].data;
  assign rob_if.single_wen  = rob[head].single_bit_write;
  assign rob_if.single_wen_vl   = vl_reg;
  assign rob_if.v_exception = rob[head].exception & rob_if.commit_ena;

  assign reached_max_a  = (rob_if.a_sigs.woffset == rob_if.a_sigs.vl - 1) || (rob_if.a_sigs.woffset == rob_if.a_sigs.vl - 2);
  assign reached_max_mu = (rob_if.mu_sigs.woffset == rob_if.mu_sigs.vl - 1) || (rob_if.mu_sigs.woffset == rob_if.mu_sigs.vl - 2);
  assign reached_max_du = (rob_if.du_sigs.woffset == rob_if.du_sigs.vl - 1) || (rob_if.du_sigs.woffset == rob_if.du_sigs.vl - 2);
  assign reached_max_m  = (rob_if.m_sigs.woffset == rob_if.m_sigs.vl - 1) || (rob_if.m_sigs.woffset == rob_if.m_sigs.vl - 2);
  assign reached_max_p  = (rob_if.p_sigs.woffset == rob_if.p_sigs.vl - 1) || (rob_if.p_sigs.woffset == rob_if.p_sigs.vl - 2);
  assign reached_max_ls = (rob_if.ls_sigs.woffset == rob_if.ls_sigs.vl - 1) || (rob_if.ls_sigs.woffset == rob_if.ls_sigs.vl - 2);

  //=====================================================
  //                   Reg file signals
  //=====================================================
  assign rfv_if.w_data = rob_if.wdata_final;
  assign rfv_if.vd = rob_if.vd_final;
  assign rfv_if.wen =rob_if.vreg_wen;
  assign rfv_if.byte_ena=rob_if.wen_final;
  //assign rfv_if.wen               = 
//  assign rfv_if.w_data            = cb[head_sel].data; 
//  assign rfv_if.rd                = cb[head_sel].vd; 
  
  //=====================================================
  //                Head and tail pointers
  //=====================================================

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
    end else if (rob_if.a_sigs.ready & rob_if.single_bit_write) begin
      vl_reg <= rob_if.a_sigs.vl;
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
    if (rob_if.a_sigs.ready) begin
      next_rob[rob_if.a_sigs.index].sew = rob_if.a_sigs.sew; 
      next_rob[a_em_if.final_index].exception = rob[a_em_if.final_index].exception | rob_if.a_sigs.exception;
      if (rob_if.a_sigs.exception & ~rob[a_em_if.final_index].exception) begin
        next_rob[a_em_if.final_index].exception_index = rob_if.a_sigs.exception_index;
      end else begin
        next_rob[a_em_if.final_index].exception_index = rob[a_em_if.final_index].exception_index;
      end
      if (rob_if.single_bit_write) begin
        next_rob[rob_if.a_sigs.index].single_bit_write = 1; 
        next_rob[rob_if.a_sigs.index].vd = rob_if.a_sigs.vd;
        next_rob[rob_if.a_sigs.index].data[rob_if.a_sigs.woffset+:2] = {rob_if.a_sigs.wdata[32], rob_if.a_sigs.wdata[0]};
        next_rob[rob_if.a_sigs.index].wen = '1; // TODO: Corner case: Masked single bit write. 
        next_rob[rob_if.a_sigs.index].valid = (rob_if.a_sigs.woffset == VLEN - 1) | (rob_if.a_sigs.woffset == VLEN - 2) | reached_max_a;
        next_rob[rob_if.a_sigs.index].commit_ack = reached_max_a;
      end else begin
        next_rob[a_em_if.final_index].single_bit_write = 0; 
        next_rob[a_em_if.final_index].sew = rob_if.a_sigs.sew;
        next_rob[a_em_if.final_index].vd = a_em_if.final_vd;
        next_rob[a_em_if.final_index].valid = a_em_if.filled_one_entry | reached_max_a;
        next_rob[a_em_if.final_index].commit_ack = reached_max_a;
        case(rob_if.a_sigs.sew)
          SEW32: begin
            next_rob[a_em_if.final_index].data[a_em_if.vd_outer_offset+:64] = rob_if.a_sigs.wdata;
            next_rob[a_em_if.final_index].wen[a_em_if.vd_wen_offset+:8] = {{4{rob_if.a_sigs.wen[1]}}, {4{rob_if.a_sigs.wen[0]}}};
          end
          SEW16: begin 
            next_rob[a_em_if.final_index].data[a_em_if.vd_outer_offset+:32] = {rob_if.a_sigs.wdata[47:32], rob_if.a_sigs.wdata[15:0]};
            next_rob[a_em_if.final_index].wen[a_em_if.vd_wen_offset+:4] = {{2{rob_if.a_sigs.wen[1]}}, {2{rob_if.a_sigs.wen[0]}}};
          end
          default: begin
            next_rob[a_em_if.final_index].data[a_em_if.vd_outer_offset+:16] = {rob_if.a_sigs.wdata[39:32], rob_if.a_sigs.wdata[7:0]};
            next_rob[a_em_if.final_index].wen[a_em_if.vd_wen_offset+:2] = rob_if.a_sigs.wen;
          end
        endcase
      end
    end
    // Next state for multiply unit result
    if (rob_if.mu_sigs.ready) begin
      next_rob[mu_em_if.final_index].single_bit_write = 0; 
      next_rob[mu_em_if.final_index].sew = rob_if.mu_sigs.sew;
      next_rob[mu_em_if.final_index].vd = mu_em_if.final_vd;
      next_rob[mu_em_if.final_index].valid = mu_em_if.filled_one_entry | reached_max_mu;
      next_rob[mu_em_if.final_index].exception = rob[mu_em_if.final_index].exception | rob_if.mu_sigs.exception;
      next_rob[mu_em_if.final_index].commit_ack = reached_max_mu;
      if (rob_if.mu_sigs.exception & ~rob[mu_em_if.final_index].exception) begin
        next_rob[mu_em_if.final_index].exception_index = rob_if.mu_sigs.exception_index;
      end else begin
        next_rob[mu_em_if.final_index].exception_index = rob[mu_em_if.final_index].exception_index;
      end
      case(rob_if.mu_sigs.sew)
        SEW32: begin
          next_rob[mu_em_if.final_index].data[mu_em_if.vd_outer_offset+:64] = rob_if.mu_sigs.wdata;
          next_rob[mu_em_if.final_index].wen[mu_em_if.vd_wen_offset+:8] = {{4{rob_if.mu_sigs.wen[1]}}, {4{rob_if.mu_sigs.wen[0]}}};
        end
        SEW16: begin 
          next_rob[mu_em_if.final_index].data[mu_em_if.vd_outer_offset+:32] = {rob_if.mu_sigs.wdata[47:32], rob_if.mu_sigs.wdata[15:0]};
          next_rob[mu_em_if.final_index].wen[mu_em_if.vd_wen_offset+:4] = {{2{rob_if.mu_sigs.wen[1]}}, {2{rob_if.mu_sigs.wen[0]}}};
        end
        default: begin
          next_rob[mu_em_if.final_index].data[mu_em_if.vd_outer_offset+:16] = {rob_if.mu_sigs.wdata[39:32], rob_if.mu_sigs.wdata[7:0]};
          next_rob[mu_em_if.final_index].wen[mu_em_if.vd_wen_offset+:2] = rob_if.mu_sigs.wen;
        end
      endcase
    end
    // Next state for divide unit result
    if (rob_if.du_sigs.ready) begin
      next_rob[du_em_if.final_index].single_bit_write = 0; 
      next_rob[du_em_if.final_index].sew = rob_if.du_sigs.sew;
      next_rob[du_em_if.final_index].vd = du_em_if.final_vd;
      next_rob[du_em_if.final_index].valid = du_em_if.filled_one_entry | reached_max_du;
      next_rob[du_em_if.final_index].commit_ack = reached_max_du;
      next_rob[du_em_if.final_index].exception = rob[du_em_if.final_index].exception | rob_if.du_sigs.exception;
      if (rob_if.du_sigs.exception & ~rob[du_em_if.final_index].exception) begin
        next_rob[du_em_if.final_index].exception_index = rob_if.du_sigs.exception_index;
      end else begin
        next_rob[du_em_if.final_index].exception_index = rob[du_em_if.final_index].exception_index;
      end
      case(rob_if.du_sigs.sew)
        SEW32: begin
          next_rob[du_em_if.final_index].data[du_em_if.vd_outer_offset+:64] = rob_if.du_sigs.wdata;
          next_rob[du_em_if.final_index].wen[du_em_if.vd_wen_offset+:8] = {{4{rob_if.du_sigs.wen[1]}}, {4{rob_if.du_sigs.wen[0]}}};
        end
        SEW16: begin 
          next_rob[du_em_if.final_index].data[du_em_if.vd_outer_offset+:32] = {rob_if.du_sigs.wdata[47:32], rob_if.du_sigs.wdata[15:0]};
          next_rob[du_em_if.final_index].wen[du_em_if.vd_wen_offset+:4] = {{2{rob_if.du_sigs.wen[1]}}, {2{rob_if.du_sigs.wen[0]}}};
        end
        default: begin
          next_rob[du_em_if.final_index].data[du_em_if.vd_outer_offset+:16] = {rob_if.du_sigs.wdata[39:32], rob_if.du_sigs.wdata[7:0]};
          next_rob[du_em_if.final_index].wen[du_em_if.vd_wen_offset+:2] = rob_if.du_sigs.wen;
        end
      endcase
    end
    // Next state for mask unit result
    if (rob_if.m_sigs.ready) begin
      next_rob[m_em_if.final_index].single_bit_write = 0; 
      next_rob[m_em_if.final_index].sew = rob_if.m_sigs.sew;
      next_rob[m_em_if.final_index].vd = m_em_if.final_vd;
      next_rob[m_em_if.final_index].valid = m_em_if.filled_one_entry | reached_max_m;
      next_rob[m_em_if.final_index].commit_ack = reached_max_m;
      next_rob[m_em_if.final_index].exception = rob[m_em_if.final_index].exception | rob_if.m_sigs.exception;
      if (rob_if.m_sigs.exception & ~rob[m_em_if.final_index].exception) begin
        next_rob[m_em_if.final_index].exception_index = rob_if.m_sigs.exception_index;
      end else begin
        next_rob[m_em_if.final_index].exception_index = rob[rob_if.m_sigs.index].exception_index;
      end
      case(rob_if.m_sigs.sew)
        SEW32: begin
          next_rob[m_em_if.final_index].data[m_em_if.vd_outer_offset+:64] = rob_if.m_sigs.wdata;
          next_rob[m_em_if.final_index].wen[m_em_if.vd_wen_offset+:8] = {{4{rob_if.m_sigs.wen[1]}}, {4{rob_if.m_sigs.wen[0]}}};
        end
        SEW16: begin 
          next_rob[m_em_if.final_index].data[m_em_if.vd_outer_offset+:32] = {rob_if.m_sigs.wdata[47:32], rob_if.m_sigs.wdata[15:0]};
          next_rob[m_em_if.final_index].wen[m_em_if.vd_wen_offset+:4] = {{2{rob_if.m_sigs.wen[1]}}, {2{rob_if.m_sigs.wen[0]}}};
        end
        default: begin
          next_rob[m_em_if.final_index].data[m_em_if.vd_outer_offset+:16] = {rob_if.m_sigs.wdata[39:32], rob_if.m_sigs.wdata[7:0]};
          next_rob[m_em_if.final_index].wen[m_em_if.vd_wen_offset+:2] = rob_if.m_sigs.wen;
        end
      endcase
    end
    // Next state for permutation unit result
    if (rob_if.p_sigs.ready) begin
      next_rob[p_em_if.final_index].single_bit_write = 0; 
      next_rob[p_em_if.final_index].sew = rob_if.p_sigs.sew;
      next_rob[p_em_if.final_index].vd = p_em_if.final_vd;
      next_rob[p_em_if.final_index].valid = p_em_if.filled_one_entry | reached_max_p;
      next_rob[p_em_if.final_index].commit_ack = reached_max_p;
      next_rob[p_em_if.final_index].exception = rob[p_em_if.final_index].exception | rob_if.p_sigs.exception;
      if (rob_if.p_sigs.exception & ~rob[p_em_if.final_index].exception) begin
        next_rob[p_em_if.final_index].exception_index = rob_if.p_sigs.exception_index;
      end else begin
        next_rob[p_em_if.final_index].exception_index = rob[p_em_if.final_index].exception_index;
      end
      case(rob_if.p_sigs.sew)
        SEW32: begin
          next_rob[p_em_if.final_index].data[p_em_if.vd_outer_offset+:64] = rob_if.p_sigs.wdata;
          next_rob[p_em_if.final_index].wen[p_em_if.vd_wen_offset+:8] = {{4{rob_if.p_sigs.wen[1]}}, {4{rob_if.p_sigs.wen[0]}}};
        end
        SEW16: begin 
          next_rob[p_em_if.final_index].data[p_em_if.vd_outer_offset+:32] = {rob_if.p_sigs.wdata[47:32], rob_if.p_sigs.wdata[15:0]};
          next_rob[p_em_if.final_index].wen[p_em_if.vd_wen_offset+:4] = {{2{rob_if.p_sigs.wen[1]}}, {2{rob_if.p_sigs.wen[0]}}};
        end
        default: begin
          next_rob[p_em_if.final_index].data[p_em_if.vd_outer_offset+:16] = {rob_if.p_sigs.wdata[39:32], rob_if.p_sigs.wdata[7:0]};
          next_rob[p_em_if.final_index].wen[p_em_if.vd_wen_offset+:2] = rob_if.p_sigs.wen;
        end
      endcase
    end
    // Next state for load store unit result
    if (rob_if.ls_sigs.ready) begin
      next_rob[ls_em_if.final_index].single_bit_write = 0; 
      next_rob[ls_em_if.final_index].sew = rob_if.ls_sigs.sew;
      next_rob[ls_em_if.final_index].vd = ls_em_if.final_vd;
      next_rob[ls_em_if.final_index].valid = ls_em_if.filled_one_entry | reached_max_ls;
      next_rob[ls_em_if.final_index].commit_ack = reached_max_ls;
      next_rob[ls_em_if.final_index].exception = rob[ls_em_if.final_index].exception | rob_if.ls_sigs.exception;
      if (rob_if.ls_sigs.exception & ~rob[ls_em_if.final_index].exception) begin
        next_rob[ls_em_if.final_index].exception_index = rob_if.ls_sigs.exception_index;
      end else begin
        next_rob[ls_em_if.final_index].exception_index = rob[ls_em_if.final_index].exception_index;
      end
      case(rob_if.ls_sigs.sew)
        SEW32: begin
          next_rob[ls_em_if.final_index].data[ls_em_if.vd_outer_offset+:64] = rob_if.ls_sigs.wdata;
          next_rob[ls_em_if.final_index].wen[ls_em_if.vd_wen_offset+:8] = {{4{rob_if.ls_sigs.wen[1]}}, {4{rob_if.ls_sigs.wen[0]}}};
        end
        SEW16: begin 
          next_rob[ls_em_if.final_index].data[ls_em_if.vd_outer_offset+:32] = {rob_if.ls_sigs.wdata[47:32], rob_if.ls_sigs.wdata[15:0]};
          next_rob[ls_em_if.final_index].wen[ls_em_if.vd_wen_offset+:4] = {{2{rob_if.ls_sigs.wen[1]}}, {2{rob_if.ls_sigs.wen[0]}}};
        end
        default: begin
          next_rob[ls_em_if.final_index].data[ls_em_if.vd_outer_offset+:16] = {rob_if.ls_sigs.wdata[39:32], rob_if.ls_sigs.wdata[7:0]};
          next_rob[ls_em_if.final_index].wen[ls_em_if.vd_wen_offset+:2] = rob_if.ls_sigs.wen;
        end
      endcase
    end
  end


endmodule
