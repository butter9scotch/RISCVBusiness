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
*   Filename:     divide_unit.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 11/7/2021
*   Description:  DIVU
*/

`include "vector_lane_if.vh"

module vdivide_unit (
  input logic CLK, nRST,
  vector_lane_if.vdivide_unit dif
);

  import rv32i_types_pkg::*;

  logic start_reg, done_reg, done, overflow, div_zero, done_early, done_early_reg, div_decode_done_flush, stop;
  logic [31:0] quotient, remainder, wdata_reg, next_wdata_reg;

  divider DVD (
    .CLK(CLK),
    .nRST(nRST),
    .dividend(dif.vs2_data),
    .divisor(dif.vs1_data),
    .is_signed(dif.is_signed_div),
    .ena((dif.start_div | start_reg) & ~done_reg),
    .start(dif.start_div & ~div_decode_done_flush & ~dif.done_du & ~stop),
    .finished(done),
    .quotient(quotient),
    .remainder(remainder)
  );

  assign dif.busy_du      = (start_reg | dif.start_div) & !done; 
  assign dif.wdata_du     = done_early_reg ? wdata_reg : dif.div_type ? quotient : remainder;
  assign dif.exception_du = dif.vs1_data == 0;  // Divide by 0
  assign dif.done_du = done & ~stop;  

  // Fix corner case: Operate only 1 or 2 element consecutively
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      start_reg <= '0;
    end else if (done) begin
      start_reg <= 0;
    end else if (dif.start_div) begin
      start_reg <= 1;
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      done_reg <= '0;
    end else if (dif.start_div) begin
      done_reg <= 0;
    end else if (done) begin
      done_reg <= 1;
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      wdata_reg <= '0;
    end else begin
      wdata_reg <= next_wdata_reg;
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      done_early_reg <= '0;
    end else if (done) begin
      done_early_reg <= 0;
    end else if (~done_early_reg) begin
      done_early_reg <= done_early;
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      stop <= '0;
    end else if (dif.stop_flush) begin
      stop <= 0;
    end else if (div_decode_done_flush && done) begin
      stop <= 1;
    end
  end

  assign overflow   = dif.start_div && (dif.vs2_data == 32'h8000_0000) && (dif.vs1_data == 32'hffff_ffff) && dif.is_signed_div;
  assign div_zero   = dif.start_div && (dif.vs1_data == 32'h0); 

  always_comb begin
    if (div_zero) begin
      done_early = 1;
      if (dif.div_type) begin // Quotient when divide by 0
        next_wdata_reg = 32'hFFFF_FFFF;
      end else begin // Remainder when divide by 0
        next_wdata_reg = dif.vs2_data;
      end
    end else if (overflow) begin
      done_early = 1;
      if (dif.div_type) begin // Quotient when overflow
        next_wdata_reg = 32'h8000_0000;
      end else begin // Remainder when overflow
        next_wdata_reg = 32'h0000_0000;
      end
    end else if (dif.vs1_data == dif.vs2_data & dif.start_div) begin
      done_early = 1;
      if (dif.div_type) begin // Quotient when equal
        next_wdata_reg = 32'h1;
      end else begin // Remainder when equal
        next_wdata_reg = 32'h0;
      end
    end else begin
      done_early = done_early_reg;
      next_wdata_reg = wdata_reg;
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      div_decode_done_flush <= '0;
    end else if (dif.stop_flush) begin
      div_decode_done_flush <= 0;
    end else if (dif.decode_done) begin
      div_decode_done_flush <= 1;
    end
  end

endmodule
