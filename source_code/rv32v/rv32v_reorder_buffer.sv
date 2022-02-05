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
*   Filename:     entry_modifier.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 1/30/2022
*   Description:  Reorder Buffer to support OoO completion within vector unit
*/

`include "rv32v_reorder_buffer_if.vh"

module rv32v_reorder_buffer # (
  parameter NUM_ENTRY = 32,
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
  } rob_entry;

  logic [$clog2(NUM_ENTRY):0] head, tail, next_head, next_tail;
  rob_entry rob [0:NUM_ENTRY-1]; 
  rob_entry next_rob [0:NUM_ENTRY-1]; 
  logic [$clog2(NUM_ENTRY)-1:0] index_a, index_mu, index_du, index_m, index_p, index_ls;
  logic [4:0] head_exception_index, excep_index_off32, excep_index_off16, excep_index_off8, excep_index_final;
  logic [4:0] vd_a, vd_mu, vd_du, vd_m, vd_p, vd_ls;
  logic reached_max_a, reached_max_mu, reached_max_du, reached_max_m, reached_max_p, reached_max_ls;
  logic filled_one_entry_a, filled_one_entry_mu, filled_one_entry_du, filled_one_entry_m, filled_one_entry_p, filled_one_entry_ls;
  logic flush;
  integer i;

  assign flush                = rob_if.branch_mispredict | rob_if.scalar_exception;
  assign head_exception_index = rob[head].exception_index;
  assign excep_index_off32    = head_exception_index[1:0] << 2;
  assign excep_index_off16    = head_exception_index[2:0] << 1;
  assign excep_index_off8     = head_exception_index[3:0];

  assign rob_if.cur_tail    = tail[$clog2(NUM_ENTRY)-1:0]; 
  assign rob_if.full        = head == tail; 
  assign rob_if.commit_done = rob[head].valid & rob_if.commit_ena;
  assign rob_if.vd_final    = rob[head].vd;
  assign rob_if.wen_final   = rob_if.rv32v_exception ? (rob[head].wen & ~(16'hffff << excep_index_final)) : rob[head].wen;
  assign rob_if.wdata_final = rob[head].data;
  assign rob_if.rv32v_exception = rob[head].exception & rob_if.commit_ena;

  assign reached_max_a  = (rob_if.woffset_a == rob_if.vl - 1) || (rob_if.woffset_a == rob_if.vl - 2);
  assign reached_max_mu = (rob_if.woffset_mu == rob_if.vl - 1) || (rob_if.woffset_mu == rob_if.vl - 2);
  assign reached_max_du = (rob_if.woffset_du == rob_if.vl - 1) || (rob_if.woffset_du == rob_if.vl - 2);
  assign reached_max_m  = (rob_if.woffset_m == rob_if.vl - 1) || (rob_if.woffset_m == rob_if.vl - 2);
  assign reached_max_p  = (rob_if.woffset_p == rob_if.vl - 1) || (rob_if.woffset_p == rob_if.vl - 2);
  assign reached_max_ls = (rob_if.woffset_ls == rob_if.vl - 1) || (rob_if.woffset_ls == rob_if.vl - 2);

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
    end else if (rob_if.commit_done) begin
      next_head = head + 1;
    end
  end

  always_comb begin
    next_tail = tail;
    if (flush) begin
        next_tail = 0;
    end else if (rob_if.alloc_ena) begin
      case (rob_if.lmul) 
        LMUL1, LMULHALF, LMULFOURTH, LMULEIGHTH: next_tail = tail + 1;
        LMUL2: next_tail = tail + 2;
        LMUL4: next_tail = tail + 4;
        LMUL8: next_tail = tail + 8;
        default: next_tail = tail;
      endcase
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

  // Modify index and vd when LMUL > 1
  always_comb begin
    case(rob_if.sew)
      SEW32: begin
        excep_index_final  = excep_index_off32;
        index_a            = rob_if.index_a + rob_if.woffset_a[4:2];
        vd_a               = rob_if.vd_a + rob_if.vd_a[4:2];
        filled_one_entry_a = rob_if.woffset_a[1:0] == 2'b11 || rob_if.woffset_a[1:0] == 2'b10;
        index_mu            = rob_if.index_mu + rob_if.woffset_mu[4:2];
        vd_mu               = rob_if.vd_mu + rob_if.vd_mu[4:2];
        filled_one_entry_mu = rob_if.woffset_mu[1:0] == 2'b11 || rob_if.woffset_mu[1:0] == 2'b10;
        index_du            = rob_if.index_du + rob_if.woffset_du[4:2];
        vd_du               = rob_if.vd_du + rob_if.vd_du[4:2];
        filled_one_entry_du = rob_if.woffset_du[1:0] == 2'b11 || rob_if.woffset_du[1:0] == 2'b10;
        index_m            = rob_if.index_m + rob_if.woffset_m[4:2];
        vd_m              = rob_if.vd_m + rob_if.vd_m[4:2];
        filled_one_entry_m = rob_if.woffset_m[1:0] == 2'b11 || rob_if.woffset_m[1:0] == 2'b10;
        index_p            = rob_if.index_p + rob_if.woffset_p[4:2];
        vd_p              = rob_if.vd_p + rob_if.vd_p[4:2];
        filled_one_entry_p = rob_if.woffset_p[1:0] == 2'b11 || rob_if.woffset_p[1:0] == 2'b10;
        index_ls            = rob_if.index_ls + rob_if.woffset_ls[4:2];
        vd_ls              = rob_if.vd_ls + rob_if.vd_ls[4:2];
        filled_one_entry_ls = rob_if.woffset_ls[1:0] == 2'b11 || rob_if.woffset_ls[1:0] == 2'b10;
      end
      SEW16: begin 
        excep_index_final  = excep_index_off16;
        index_a            = rob_if.index_a + rob_if.woffset_a[5:3];
        vd_a               = rob_if.vd_a + rob_if.woffset_a[5:3];
        filled_one_entry_a = rob_if.woffset_a[2:0] == 3'b111 || rob_if.woffset_a[2:0] == 3'b110;
        index_mu            = rob_if.index_mu + rob_if.woffset_mu[5:3];
        vd_mu               = rob_if.vd_mu + rob_if.woffset_mu[5:3];
        filled_one_entry_mu = rob_if.woffset_mu[2:0] == 3'b111 || rob_if.woffset_mu[2:0] == 3'b110;
        index_du            = rob_if.index_du + rob_if.woffset_du[5:3];
        vd_du               = rob_if.vd_du + rob_if.woffset_du[5:3];
        filled_one_entry_du = rob_if.woffset_du[2:0] == 3'b111 || rob_if.woffset_du[2:0] == 3'b110;
        index_m            = rob_if.index_m + rob_if.woffset_m[5:3];
        vd_m               = rob_if.vd_m + rob_if.woffset_m[5:3];
        filled_one_entry_m = rob_if.woffset_m[2:0] == 3'b111 || rob_if.woffset_m[2:0] == 3'b110;
        index_p            = rob_if.index_p + rob_if.woffset_p[5:3];
        vd_p               = rob_if.vd_p + rob_if.woffset_p[5:3];
        filled_one_entry_p = rob_if.woffset_p[2:0] == 3'b111 || rob_if.woffset_p[2:0] == 3'b110;
        index_ls            = rob_if.index_ls + rob_if.woffset_ls[5:3];
        vd_ls               = rob_if.vd_ls + rob_if.woffset_ls[5:3];
        filled_one_entry_ls = rob_if.woffset_ls[2:0] == 3'b111 || rob_if.woffset_ls[2:0] == 3'b110;
      end
      default: begin
        excep_index_final  = excep_index_off8;
        index_a            = rob_if.index_a + rob_if.woffset_a[6:4];
        vd_a               = rob_if.vd_a + rob_if.woffset_a[6:4];
        filled_one_entry_a = rob_if.woffset_a[2:0] == 4'b1111 || rob_if.woffset_a[2:0] == 4'b1110;
        index_mu            = rob_if.index_mu + rob_if.woffset_mu[6:4];
        vd_mu               = rob_if.vd_mu + rob_if.woffset_mu[6:4];
        filled_one_entry_mu = rob_if.woffset_mu[2:0] == 4'b1111 || rob_if.woffset_mu[2:0] == 4'b1110;
        index_du            = rob_if.index_du + rob_if.woffset_du[6:4];
        vd_du               = rob_if.vd_du + rob_if.woffset_du[6:4];
        filled_one_entry_du = rob_if.woffset_du[2:0] == 4'b1111 || rob_if.woffset_du[2:0] == 4'b1110;
        index_m            = rob_if.index_m + rob_if.woffset_m[6:4];
        vd_m               = rob_if.vd_m + rob_if.woffset_m[6:4];
        filled_one_entry_m = rob_if.woffset_m[2:0] == 4'b1111 || rob_if.woffset_m[2:0] == 4'b1110;
        index_p            = rob_if.index_p + rob_if.woffset_p[6:4];
        vd_p               = rob_if.vd_p + rob_if.woffset_p[6:4];
        filled_one_entry_p = rob_if.woffset_p[2:0] == 4'b1111 || rob_if.woffset_p[2:0] == 4'b1110;
        index_ls            = rob_if.index_ls + rob_if.woffset_ls[6:4];
        vd_ls               = rob_if.vd_ls + rob_if.woffset_ls[6:4];
        filled_one_entry_ls = rob_if.woffset_ls[2:0] == 4'b1111 || rob_if.woffset_ls[2:0] == 4'b1110;
      end 
    endcase 
  end

  always_comb begin
    // Set default value
    next_rob = rob;
    /*for (i = 0; i < 2; i++) begin
        next_rob[i] = rob[i];
    end */
    // Clear head entry when committed
    if (rob_if.commit_done) begin
      next_rob[head] = '0;
    end
    // Next state for arithemtic unit result
    if (rob_if.ready_a) begin
      next_rob[index_a].vd = vd_a;
      next_rob[index_a].valid = filled_one_entry_a | reached_max_a;
      next_rob[index_a].exception = rob[index_a].exception | rob_if.exception_a;
      if (rob_if.exception_a & ~rob[index_a].exception) begin
        next_rob[index_a].exception_index = rob_if.exception_index_a;
      end else begin
        next_rob[index_a].exception_index = rob[index_a].exception_index;
      end
      case(rob_if.sew)
        SEW32: begin
          next_rob[index_a].data = rob[index_a].data << 64 | rob_if.wdata_a;
          next_rob[index_a].wen = rob[index_a].wen << 8 | {{4{rob_if.wen_a[1]}}, {4{rob_if.wen_a[0]}}};
        end
        SEW16: begin 
          next_rob[index_a].data = rob[index_a].data << 32 | {rob_if.wdata_a[47:32], rob_if.wdata_a[15:0]};
          next_rob[index_a].wen = rob[index_a].wen << 4 | {{2{rob_if.wen_a[1]}}, {2{rob_if.wen_a[0]}}};
        end
        default: begin
          next_rob[index_a].data = rob[index_a].data << 16 | {rob_if.wdata_a[39:32], rob_if.wdata_a[7:0]};
          next_rob[index_a].wen = rob[index_a].wen << 2 | rob_if.wen_a;
        end
      endcase
    end
    // Next state for multiply unit result
    if (rob_if.ready_mu) begin
      next_rob[index_mu].vd = vd_mu;
      next_rob[index_mu].valid = filled_one_entry_mu | reached_max_mu;
      next_rob[index_mu].exception = rob[index_mu].exception | rob_if.exception_mu;
      if (rob_if.exception_mu & ~rob[index_mu].exception) begin
        next_rob[index_mu].exception_index = rob_if.exception_index_mu;
      end else begin
        next_rob[index_mu].exception_index = rob[index_mu].exception_index;
      end
      case(rob_if.sew)
        SEW32: begin
          next_rob[index_mu].data = rob[index_mu].data << 64 | rob_if.wdata_mu;
          next_rob[index_mu].wen = rob[index_mu].wen << 8 | {{4{rob_if.wen_mu[1]}}, {4{rob_if.wen_mu[0]}}};
        end
        SEW16: begin 
          next_rob[index_mu].data = rob[index_mu].data << 32 | {rob_if.wdata_mu[47:32], rob_if.wdata_mu[15:0]};
          next_rob[index_mu].wen = rob[index_mu].wen << 4 | {{2{rob_if.wen_mu[1]}}, {2{rob_if.wen_mu[0]}}};
        end
        default: begin
          next_rob[index_mu].data = rob[index_mu].data << 16 | {rob_if.wdata_mu[39:32], rob_if.wdata_mu[7:0]};
          next_rob[index_mu].wen = rob[index_mu].wen << 2 | rob_if.wen_mu;
        end
      endcase
    end
    // Next state for divide unit result
    if (rob_if.ready_du) begin
      next_rob[index_du].vd = vd_du;
      next_rob[index_du].valid = filled_one_entry_du | reached_max_du;
      next_rob[index_du].exception = rob[index_du].exception | rob_if.exception_du;
      if (rob_if.exception_du & ~rob[index_du].exception) begin
        next_rob[index_du].exception_index = rob_if.exception_index_du;
      end else begin
        next_rob[index_du].exception_index = rob[index_du].exception_index;
      end
      case(rob_if.sew)
        SEW32: begin
          next_rob[index_du].data = rob[index_du].data << 64 | rob_if.wdata_du;
          next_rob[index_du].wen = rob[index_du].wen << 8 | {{4{rob_if.wen_du[1]}}, {4{rob_if.wen_du[0]}}};
        end
        SEW16: begin 
          next_rob[index_du].data = rob[index_du].data << 32 | {rob_if.wdata_du[47:32], rob_if.wdata_du[15:0]};
          next_rob[index_du].wen = rob[index_du].wen << 4 | {{2{rob_if.wen_du[1]}}, {2{rob_if.wen_du[0]}}};
        end
        default: begin
          next_rob[index_du].data = rob[index_du].data << 16 | {rob_if.wdata_du[39:32], rob_if.wdata_du[7:0]};
          next_rob[index_du].wen = rob[index_du].wen << 2 | rob_if.wen_du;
        end
      endcase
    end
    // Next state for mask unit result
    if (rob_if.ready_m) begin
      next_rob[index_m].vd = vd_m;
      next_rob[index_m].valid = filled_one_entry_m | reached_max_m;
      next_rob[index_m].exception = rob[index_m].exception | rob_if.exception_m;
      if (rob_if.exception_m & ~rob[index_m].exception) begin
        next_rob[index_m].exception_index = rob_if.exception_index_m;
      end else begin
        next_rob[index_m].exception_index = rob[index_m].exception_index;
      end
      case(rob_if.sew)
        SEW32: begin
          next_rob[index_m].data = rob[index_m].data << 64 | rob_if.wdata_m;
          next_rob[index_m].wen = rob[index_m].wen << 8 | {{4{rob_if.wen_m[1]}}, {4{rob_if.wen_m[0]}}};
        end
        SEW16: begin 
          next_rob[index_m].data = rob[index_m].data << 32 | {rob_if.wdata_m[47:32], rob_if.wdata_m[15:0]};
          next_rob[index_m].wen = rob[index_m].wen << 4 | {{2{rob_if.wen_m[1]}}, {2{rob_if.wen_m[0]}}};
        end
        default: begin
          next_rob[index_m].data = rob[index_m].data << 16 | {rob_if.wdata_m[39:32], rob_if.wdata_m[7:0]};
          next_rob[index_m].wen = rob[index_m].wen << 2 | rob_if.wen_m;
        end
      endcase
    end
    // Next state for permutation unit result
    if (rob_if.ready_p) begin
      next_rob[index_p].vd = vd_p;
      next_rob[index_p].valid = filled_one_entry_p | reached_max_p;
      next_rob[index_p].exception = rob[index_p].exception | rob_if.exception_p;
      if (rob_if.exception_p & ~rob[index_p].exception) begin
        next_rob[index_p].exception_index = rob_if.exception_index_p;
      end else begin
        next_rob[index_p].exception_index = rob[index_p].exception_index;
      end
      case(rob_if.sew)
        SEW32: begin
          next_rob[index_p].data = rob[index_p].data << 64 | rob_if.wdata_p;
          next_rob[index_p].wen = rob[index_p].wen << 8 | {{4{rob_if.wen_p[1]}}, {4{rob_if.wen_p[0]}}};
        end
        SEW16: begin 
          next_rob[index_p].data = rob[index_p].data << 32 | {rob_if.wdata_p[47:32], rob_if.wdata_p[15:0]};
          next_rob[index_p].wen = rob[index_p].wen << 4 | {{2{rob_if.wen_p[1]}}, {2{rob_if.wen_p[0]}}};
        end
        default: begin
          next_rob[index_p].data = rob[index_p].data << 16 | {rob_if.wdata_p[39:32], rob_if.wdata_p[7:0]};
          next_rob[index_p].wen = rob[index_p].wen << 2 | rob_if.wen_p;
        end
      endcase
    end
    // Next state for load store unit result
    if (rob_if.ready_ls) begin
      next_rob[index_ls].vd = vd_ls;
      next_rob[index_ls].valid = filled_one_entry_ls | reached_max_ls;
      next_rob[index_ls].exception = rob[index_ls].exception | rob_if.exception_ls;
      if (rob_if.exception_ls & ~rob[index_ls].exception) begin
        next_rob[index_ls].exception_index = rob_if.exception_index_ls;
      end else begin
        next_rob[index_ls].exception_index = rob[index_ls].exception_index;
      end
      case(rob_if.sew)
        SEW32: begin
          next_rob[index_ls].data = rob[index_ls].data << 64 | rob_if.wdata_ls;
          next_rob[index_ls].wen = rob[index_ls].wen << 8 | {{4{rob_if.wen_ls[1]}}, {4{rob_if.wen_ls[0]}}};
        end
        SEW16: begin 
          next_rob[index_ls].data = rob[index_ls].data << 32 | {rob_if.wdata_ls[47:32], rob_if.wdata_ls[15:0]};
          next_rob[index_ls].wen = rob[index_ls].wen << 4 | {{2{rob_if.wen_ls[1]}}, {2{rob_if.wen_ls[0]}}};
        end
        default: begin
          next_rob[index_ls].data = rob[index_ls].data << 16 | {rob_if.wdata_ls[39:32], rob_if.wdata_ls[7:0]};
          next_rob[index_ls].wen = rob[index_ls].wen << 2 | rob_if.wen_ls;
        end
      endcase
    end
  end

endmodule
