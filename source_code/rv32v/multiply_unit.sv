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

`include "vector_lane_if.vh"

module multiply_unit (
  input logic CLK, nRST,
  vector_lane_if.multiply_unit mif
);

  import rv32v_types_pkg::*;

  logic start_reg, done;
  logic [63:0] product;
  logic [31:0] product_high_sew32, product_low_sew32, selected_product, final_product, product_mod, product_3in;
  logic [15:0] product_high_sew16, product_low_sew16;
  logic [7:0] product_high_sew8, product_low_sew8;

  rv32v_multiplier MULU (
    .CLK(CLK),
    .nRST(nRST),
    .multiplicand(mif.vs2_data),
    .multiplier(mif.vs1_data),
    .is_signed(mif.is_signed_mul),
    .start(mif.start_mu),
    .finished(done),
    .product(product)
  );

  assign mif.busy_mu      = (start_reg | mif.start_mu) & !done; 
  assign final_product    = mif.mul_widen_ena ? product[31:0] : selected_product;
  assign product_mod      = mif.multiply_pos_neg ? final_product : (0-final_product);
  assign mif.wdata_mu     = mif.multiply_type ? product_mod + mif.vs3_data : final_product;
  assign mif.exception_mu = 0; // TODO: Add signals if needed

  // Fix corner case: Operate only 1 or 2 element consecutively
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      start_reg <= '0;
    end else if (done) begin
      start_reg <= 0;
    end else if (mif.start_mu) begin
      start_reg <= 1;
    end
  end

  assign product_low_sew32  = product[31:0];
  assign product_high_sew32 = product[63:32]; 
  assign product_low_sew16  = product[15:0];
  assign product_high_sew16 = product[32:16]; 
  assign product_low_sew8   = product[7:0];
  assign product_high_sew8  = product[15:8];
  always_comb begin
    case (mif.sew) 
      SEW8:
        if (mif.high_low) selected_product = product_high_sew8;
        else selected_product = product_low_sew8;
      SEW16:
        if (mif.high_low) selected_product = product_high_sew16;
        else selected_product = product_low_sew16;
      SEW32:
        if (mif.high_low) selected_product = product_high_sew32;
        else selected_product = product_low_sew32;
      default:
        selected_product = '0;
    endcase
  end 

endmodule
