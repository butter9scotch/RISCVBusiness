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
*   Filename:     completion_buffer.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 2/12/2022
*   Description:  Completion Buffer to maintain global program order
*/

`include "completion_buffer_if.vh"

module completion_buffer # (
  parameter NUM_ENTRY = 16
)
(
  input CLK, nRST,
  completion_buffer_if.cb cb_if,
  rv32i_reg_file_if.writeback rf_if
);

  import rv32i_types_pkg::*;

  typedef struct packed {
    word_t data;
    logic [4:0] vd;
    logic valid;
    logic exception;
    logic branch_mispredict_mal;
    logic wen;
    logic rv32v;
    logic rv32f;
  } cb_entry;

  logic [$clog2(NUM_ENTRY):0] head, tail, next_head, next_tail;
  logic [$clog2(NUM_ENTRY) - 1:0] head_sel;
  cb_entry cb [0:NUM_ENTRY-1]; 
  cb_entry next_cb [0:NUM_ENTRY-1]; 
  logic move_head, flush_cb;
  integer i;

  assign head_sel = head[$clog2(NUM_ENTRY)-1:0];
  // assign tail_sel = tail[$clog2(NUM_ENTRY)-1:0];

  assign cb_if.cur_tail          = tail[$clog2(NUM_ENTRY)-1:0]; 
  //Register file signals here... this is just to stay consistent with the vector unit
  assign rf_if.w_data            = cb[head_sel].data; 
  assign rf_if.rd                = cb[head_sel].vd; 
  assign rf_if.wen               = cb[head_sel].valid & ~cb_if.flush & cb[head_sel].wen; 
  // assign cb_if.scalar_commit_ena = cb[head_sel].valid & ~cb_if.flush & cb[head_sel].wen;
  assign cb_if.vd_final          = cb[head_sel].vd; 
  assign cb_if.wdata_final       = cb[head_sel].data; 
  assign cb_if.full              = head[$clog2(NUM_ENTRY)-1:0] == tail[$clog2(NUM_ENTRY)-1:0] && head[$clog2(NUM_ENTRY)] != tail[$clog2(NUM_ENTRY)]; 
  assign cb_if.empty             = head == tail; 
  assign cb_if.flush             = cb[head_sel].exception | cb[head_sel].branch_mispredict_mal;
  assign cb_if.exception         = cb[head_sel].exception | cb_if.rv32v_exception; // WEN to epc register
  //assign cb_if.scalar_commit_ena = cb[head_sel].valid & ~cb_if.flush;
  assign cb_if.rv32v_commit_ena  = cb[head_sel].rv32v & ~cb[head_sel].wen; // For vector instr that is not writing back to scalar reg
  assign cb_if.rv32f_commit_ena  = cb[head_sel].rv32f & cb[head_sel].valid & ~cb_if.flush & ~cb[head_sel].wen; 
  assign cb_if.tb_read           = move_head;
  assign move_head               = cb_if.rv32v_commit_ena ? cb_if.rv32v_commit_done : cb[head_sel].valid & ~cb_if.flush;
  assign flush_cb                = cb_if.flush | cb_if.rv32v_exception;

  //assign cb_if.branch_mispredict_ena = cb[head_sel].branch_mispredict_mal & ~cb[head_sel].exception;
  //assign cb_if.mal_priv = cb[head_sel].branch_mispredict_mal & cb[head_sel].exception;
  assign cb_if.branch_mispredict_ena = 0;
  assign cb_if.mal_priv = 0;
 
  //Hazard unit logic
  assign hazard_if.rob_full = cb_if.full;

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
    if (flush_cb) begin
      next_head = 0;
    end else if (move_head) begin
      next_head = head + 1;
    end
  end

  always_comb begin
    next_tail = tail;
    if (flush_cb) begin
      next_tail = 0;
    end else if (cb_if.alloc_ena & ~cb_if.full & (cb_if.opcode != opcode_t'(0))) begin
      next_tail = tail + 1;
    end
  end

  // CB LOGIC
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      for (i = 0; i < NUM_ENTRY; i++) begin
        cb[i] <= '0;
      end
    end else if (flush_cb) begin
      for (i = 0; i < NUM_ENTRY; i++) begin
        cb[i] <= '0;
      end
    end else begin
      for (i = 0; i < NUM_ENTRY; i++) begin
        cb[i] <= next_cb[i];
      end
    end
  end 

  always_comb begin
    // Set default value
    next_cb = cb;
    // Clear head entry when committed
    if (move_head) begin
      next_cb[head_sel] = '0;
    end
    // Illegal instr
    /*if (cb_if.alloc_ena) begin
      next_cb[tail].epc = cb_if.pc;
      if (cb_if.illegal_instr) begin
        next_cb[tail].exception = 1;
      end 
    end */
    // Allocate entry for vector instr
    if (cb_if.alloc_ena & cb_if.rv32v_instr) begin
      next_cb[tail].rv32v = 1;
      if (cb_if.rv32v_wb_scalar_ena) begin
        next_cb[tail].wen = 1;
      end else begin
        next_cb[tail].wen = 0;
      end
    end
    // Next state for arithemtic unit result
    if (cb_if.ready_a) begin
      next_cb[cb_if.index_a].data = cb_if.wdata_a; // if branch mispredict, wdat = pc : if exception, wdat = epc : else, wdat = aluresult
      next_cb[cb_if.index_a].vd = cb_if.vd_a;
      next_cb[cb_if.index_a].valid = cb_if.valid_a; // valid if ALU result is valid AND branch is not mispredicted
      next_cb[cb_if.index_a].exception = cb_if.exception_a;
      next_cb[cb_if.index_a].branch_mispredict_mal = cb_if.branch_mispredict;
      next_cb[cb_if.index_a].wen = cb_if.wen_a; // if branch or exception, wen = 0 : else, wen = 1
      next_cb[cb_if.index_a].rv32v = 0;
      next_cb[cb_if.index_a].rv32f = 0;
    end
    // Next state for multiply unit result
    if (cb_if.ready_mu) begin
      next_cb[cb_if.index_mu].data = cb_if.wdata_mu;
      next_cb[cb_if.index_mu].vd = cb_if.vd_mu;
      next_cb[cb_if.index_mu].valid = 1;
      next_cb[cb_if.index_mu].exception = cb_if.exception_mu;
      next_cb[cb_if.index_mu].branch_mispredict_mal = 0;
      next_cb[cb_if.index_mu].wen = 1;
      next_cb[cb_if.index_mu].rv32v = 0;
      next_cb[cb_if.index_mu].rv32f = 0;
    end
    // Next state for divide unit result
    if (cb_if.ready_du) begin
      next_cb[cb_if.index_du].data = cb_if.wdata_du;
      next_cb[cb_if.index_du].vd = cb_if.vd_du;
      next_cb[cb_if.index_du].valid = 1;
      next_cb[cb_if.index_du].exception = cb_if.exception_du;
      next_cb[cb_if.index_du].branch_mispredict_mal = 0;
      next_cb[cb_if.index_du].wen = 1;
      next_cb[cb_if.index_du].rv32v = 0;
      next_cb[cb_if.index_du].rv32f = 0;
    end
    // Next state for loadstore unit result
    if (cb_if.ready_ls) begin
      next_cb[cb_if.index_ls].data = cb_if.wdata_ls;
      next_cb[cb_if.index_ls].vd = cb_if.vd_ls;
      next_cb[cb_if.index_ls].valid = 1;
      next_cb[cb_if.index_ls].exception = cb_if.exception_ls;
      next_cb[cb_if.index_ls].branch_mispredict_mal = cb_if.mal_ls;
      next_cb[cb_if.index_ls].wen = cb_if.wen_ls; //wrong
      next_cb[cb_if.index_ls].rv32v = 0;
      next_cb[cb_if.index_ls].rv32f = 0;
    end
    // Next state for vector unit result
    if (cb_if.rv32v_wb_scalar_ready) begin
      next_cb[cb_if.rv32v_wb_scalar_index].data = cb_if.rv32v_wb_scalar_data;
      next_cb[cb_if.rv32v_wb_scalar_index].vd = cb_if.rv32v_wb_vd; 
      next_cb[cb_if.rv32v_wb_scalar_index].valid = 1;
      next_cb[cb_if.rv32v_wb_scalar_index].exception = cb_if.rv32v_wb_exception;
      next_cb[cb_if.rv32v_wb_scalar_index].branch_mispredict_mal = 0;
      next_cb[cb_if.rv32v_wb_scalar_index].rv32f = 0;
    end
    // TODO: Add floating point signals when integrating FPU
  end

endmodule
