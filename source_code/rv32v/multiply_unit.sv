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
  
  logic start_reg, next_start_reg;
  logic [31:0] vs1_data, vs2_data;
  logic done, next_done;
  logic [63:0] product;
  logic [31:0] product_high_sew32, product_low_sew32, selected_product, final_product, product_mod, product_3in;
  logic [15:0] product_high_sew16, product_low_sew16;
  logic [7:0] product_high_sew8, product_low_sew8;

  rv32v_multiplier MULU (
    .CLK(CLK),
    .nRST(nRST),
    .multiplicand(vs2_data),
    .multiplier(vs1_data),
    .is_signed(mif.is_signed_mul),
    .start(start_reg),
    .finished(done),
    .next_finished(next_done),
    .product(product)
  );

  // assign mif.next_busy_mu = (start_reg | mif.start_mu) & !next_done;
  // assign mif.busy_mu      = (start_reg | mif.start_mu) & !done; 
  assign final_product    = mif.mul_widen_ena ? product[31:0] : selected_product;
  assign product_mod      = mif.multiply_pos_neg ? final_product : (0-final_product);
  assign mif.wdata_mu     = mif.multiply_type ? product_mod + mif.vs3_data : final_product;
  assign mif.exception_mu = 0; // TODO
  assign mif.done_mu      = done; 
  
  assign vs1_data =  (mif.sew == SEW16) & mif.is_signed_mul[0] ? {{16{mif.vs1_data[15]}}, mif.vs1_data[15:0]}: 
                     (mif.sew == SEW8)  & mif.is_signed_mul[0] ? {{24{mif.vs1_data[7]}}, mif.vs1_data[7:0]}: mif.vs1_data;
  assign vs2_data = (mif.sew == SEW16)  & mif.is_signed_mul[1] ? {{16{mif.vs2_data[15]}}, mif.vs2_data[15:0]}: 
                    (mif.sew == SEW8)   & mif.is_signed_mul[1] ? {{24{mif.vs2_data[7]}}, mif.vs2_data[7:0]}: mif.vs2_data;

  // Fix corner case: Operate only 1 or 2 element consecutively

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      start_reg <= '0;
    end else if (mif.decode_done) begin
      start_reg <= 0;
    end else if (mif.start_mu) begin
      start_reg <= 1;
    end
  end

  // logic done1, done2;
  // always_ff @(posedge CLK, negedge nRST) begin
  //   if (~nRST) begin
  //     done1 <= mif.decode_done;
  //     done2 <= done1;
  //     done <= done2;
  //   end else if (done) begin
  //     done1 <= 0;
  //     done2 <= 0;
  //     done  <= 0;
  //   end else begin
  //     done1 <= mif.decode_done & mif.mul_ena;
  //     done2 <= done1;
  //     done <= done2;
  //   end
  // end

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
