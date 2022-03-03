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
*   Filename:     multiply_unit.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 11/7/2021
*   Description:  MULU
*/

`include "multiply_unit_if.vh"

module multiply_unit (
  input logic CLK, nRST,
  multiply_unit_if.execute mif
);

  import rv32m_pkg::*;
  import rv32i_types_pkg::*;
  
  logic start_reg;
  logic done, next_done;
  logic [63:0] product;
  logic [31:0] product_high_sew32, product_low_sew32;  
  logic [31:0] multiplicand, multiplier;  
  sign_type_t is_signed;

  multiplier MULU (
    .CLK(CLK),
    .nRST(nRST),
    .multiplicand(multiplicand),
    .multiplier(multiplier),
    .is_signed(is_signed),
    .start(ena_ff0),
    .finished(done),
    .next_finished(next_done),
    .product(product)
  );

  logic high_low_sel_ff0, high_low_sel_ff1, high_low_sel_ff2; 
  always_ff @(posedge CLK or negedge nRST) begin
    if (~nRST) begin 
      high_low_sel_ff0 <= 0; 
      high_low_sel_ff1 <= 0; 
      high_low_sel_ff2 <= 0; 
      // ena_ff0 <= 0; // something like this 
      // ena_ff1 <= 0; // something like this 
      // ena_ff2 <= 0; // something like this 
    end else begin
      high_low_sel_ff0 <= mif.high_low_sel;
      high_low_sel_ff1 <= high_low_sel_ff0;
      high_low_sel_ff2 <= high_low_sel_ff1;
      // ena_ff0 <= mif.start_mu;
      // ena_ff1 <= ena_ff0;
      // ena_ff2 <= ena_ff1;
    end
  end

  assign multiplicand  = mif.is_signed == SIGNED_UNSIGNED ? mif.rs1_data : mif.rs2_data;
  assign multiplier    = mif.is_signed == SIGNED_UNSIGNED ? mif.rs2_data : mif.rs1_data;
  assign is_signed     = mif.is_signed == SIGNED_UNSIGNED ? UNSIGNED_SIGNED : mif.is_signed;
  assign mif.done_mu   = done;
  assign mif.reg_rd_mu = mif.reg_rd;
  assign mif.wdata_mu = (high_low_sel_ff2) ? product_high_sew32 : product_low_sew32;
  assign mif.busy_mu = mif.start_mu & ~mif.done_mu;

  assign product_low_sew32  = product[31:0];
  assign product_high_sew32 = product[63:32]; 
  
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      start_reg <= '0;
    end else if (mif.decode_done) begin
      start_reg <= 0;
    end else if (mif.start_mu) begin
      start_reg <= 1;
    end
  end

endmodule
