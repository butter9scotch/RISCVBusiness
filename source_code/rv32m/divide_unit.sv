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

`include "divide_unit_if.vh"

module divide_unit (
  input logic CLK, nRST,
  divide_unit_if.execute dif
);

  import rv32i_types_pkg::*;

  logic start_reg, done_reg, done, div_type_reg, overflow, div_zero, is_signed_reg;
  logic [31:0] quotient, remainder;
  logic [31:0] q;
  logic [4:0] reg_rd_du; 
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_du; 
  typedef enum logic [1:0] { OFF, BUSY } div_state_t;
  div_state_t start_div_state;

  divider DVD (
    .CLK(CLK),
    .nRST(nRST),
    .dividend(dif.rs1_data),
    .divisor(dif.rs2_data),
    .ena(dif.busy_du & ~overflow & ~div_zero),
    .is_signed(dif.start_div ? dif.is_signed_div : is_signed_reg),
    .start(dif.start_div & ~overflow & ~div_zero),
    .finished(done),
    .quotient(quotient),
    .remainder(remainder)
  );


  assign overflow   = dif.start_div && (dif.rs1_data == 32'h8000_0000) && (dif.rs2_data == 32'hffff_ffff) && dif.is_signed_div;
  assign div_zero   = dif.start_div && (dif.rs2_data == 32'h0); 

  //assign dif.busy_du      = (start_reg | dif.start_div) & !done_reg; 
  //assign dif.wdata_du     = div_type_reg ? q : remainder;
  //assign dif.done_du      = done;  

  assign q = (dif.rs2_data == 0) && dif.is_signed_div  ? 32'hFFFF_FFFF : 
             (dif.rs2_data == 0) && ~dif.is_signed_div ? 32'h7FFF_FFFF : quotient;

  //assign dif.done_du = dif.rs2_data == 0 ? 1 : done;

  always_comb begin
    if (div_zero) begin
      dif.busy_du = 0; 
      dif.done_du = 1;
      if (dif.div_type) begin // Quotient when divide by 0
        dif.wdata_du = dif.is_signed_div ? 32'hFFFF_FFFF : 32'h7FFF_FFFF;
      end else begin // Remainder when divide by 0
        dif.wdata_du = dif.rs1_data;
      end
    end else if (overflow) begin
      dif.busy_du = 0; 
      dif.done_du = 1;
      if (dif.div_type) begin // Quotient when overflow
        dif.wdata_du = 32'h8000_0000;
      end else begin // Remainder when overflow
        dif.wdata_du = 32'h0000_0000;
      end
    end else begin
      dif.busy_du = (start_reg | dif.start_div) & !done_reg; 
      dif.done_du = done;
      if (div_type_reg) begin // Quotient when normal operation
        dif.wdata_du = quotient;
      end else begin // Remainder when normal operation
        dif.wdata_du = remainder;
      end
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      start_reg <= '0;
      div_type_reg <= '0;
      is_signed_reg <= 0;
    end else if (done) begin
      start_reg <= 0;
    end else if (dif.start_div & ~overflow & ~div_zero) begin
      start_reg <= 1;
      div_type_reg <= dif.div_type;
      is_signed_reg <= dif.is_signed_div;
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      done_reg <= '0;
    end else begin
      done_reg <= done;
    end
  end

  // always_ff @(posedge CLK or negedge nRST) begin
  //   if (~nRST) begin
  //     start_div_state = OFF;
  //   end else begin
  //     case (start_div_state)
  //     OFF:  if (dif.start_div) start_div_state <= BUSY;
  //     BUSY: if (done) start_div_state <= OFF;
  //     endcase
  //   end
  // end

endmodule
