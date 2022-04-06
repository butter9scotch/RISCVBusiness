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

module vmultiply_unit (
  input logic CLK, nRST,
  vector_lane_if.vmultiply_unit mif
);

  import rv32i_types_pkg::*;
  
  logic start_reg, next_start_reg;
  logic [31:0] vs1_data, vs2_data, vs3_data;
  logic done, next_done;
  logic [63:0] product;
  logic [31:0] product_high_sew32, product_low_sew32, selected_product, final_product, product_mod, product_3in;
  logic [15:0] product_high_sew16, product_low_sew16;
  logic [7:0] product_high_sew8, product_low_sew8;
  logic [31:0] multiplicand;
  logic mul_decode_done_flush;
  logic stop_flush;
  logic multiply_pos_neg_ff0, multiply_pos_neg_ff1, multiply_pos_neg_ff2; 

  rv32v_multiplier MULU (
    .CLK(CLK),
    .nRST(nRST),
    .multiplicand(multiplicand),
    .multiplier(vs1_data),
    .is_signed(mif.is_signed_mul),
    .start(mif.start_mu & ~mul_decode_done_flush & ~mif.decode_done),
    .finished(done),
    .next_finished(next_done),
    .product(product)
  );

  // assign mif.next_busy_mu = (start_reg | mif.start_mu) & !next_done;
  // assign mif.busy_mu      = (start_reg | mif.start_mu) & !done; 
  // assign final_product    = mif.mul_widen_ena ? product[31:0] : selected_product;
  assign final_product    =  selected_product;
  // assign product_mod      = mif.multiply_pos_neg ? final_product : (0-final_product);
  assign product_mod      = multiply_pos_neg_ff2 ? (0 - final_product) : final_product;
  // assign mif.wdata_mu     = mif.multiply_type == MACC ? product_mod + mif.vs3_data : final_product;
  assign mif.exception_mu = 0; // TODO
  assign mif.done_mu      = done; 

  assign multiplicand = (mif.multiply_type == MADD) | (mif.multiply_type == MSUB) ? vs3_data : vs2_data;

  logic [31:0] addend_ff0, addend_ff1, addend_ff2; //This is the thing added to the product during fused multiply

  multiply_type_t multiply_type_ff0, multiply_type_ff1, multiply_type_ff2;
  logic mul_widen_ena_ff0, mul_widen_ena_ff1, mul_widen_ena_ff2;
  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
      addend_ff0 <= 0;
      addend_ff1 <= 0;
      addend_ff2 <= 0;

      multiply_type_ff0 <= NOT_FUSED_MUL;
      multiply_type_ff1 <= 0;
      multiply_type_ff2 <= 0;
      
      mul_widen_ena_ff0 <= 0;
      mul_widen_ena_ff1 <= 0;
      mul_widen_ena_ff2 <= 0;

      multiply_pos_neg_ff0 <= 0;
      multiply_pos_neg_ff1 <= 0;
      multiply_pos_neg_ff2 <= 0;

    end else begin
      addend_ff0 <= (mif.multiply_type == MADD) | (mif.multiply_type == MSUB) ? vs2_data : vs3_data;
      addend_ff1 <= addend_ff0;
      addend_ff2 <= addend_ff1;
      
      multiply_type_ff0 <= mif.multiply_type;
      multiply_type_ff1 <= multiply_type_ff0;
      multiply_type_ff2 <= multiply_type_ff1;
      
      mul_widen_ena_ff0 <= mif.mul_widen_ena;
      mul_widen_ena_ff1 <= mul_widen_ena_ff0;
      mul_widen_ena_ff2 <= mul_widen_ena_ff1;

      multiply_pos_neg_ff0 <= mif.multiply_pos_neg;
      multiply_pos_neg_ff1 <= multiply_pos_neg_ff0;
      multiply_pos_neg_ff2 <= multiply_pos_neg_ff1;

    end
  end

  always_comb begin
    case (multiply_type_ff2) 
      MACC, MADD, MSAC, MSUB: mif.wdata_mu = product_mod + addend_ff2;
      default: mif.wdata_mu = final_product;
    endcase
  end
  
  assign vs1_data =  (mif.sew == SEW16) & mif.is_signed_mul[0] ? {{16{mif.vs1_data[15]}}, mif.vs1_data[15:0]}: 
                     (mif.sew == SEW8)  & mif.is_signed_mul[0] ? {{24{mif.vs1_data[7]}}, mif.vs1_data[7:0]}: mif.vs1_data;
  assign vs2_data = (mif.sew == SEW16)  & mif.is_signed_mul[1] ? {{16{mif.vs2_data[15]}}, mif.vs2_data[15:0]}: 
                    (mif.sew == SEW8)   & mif.is_signed_mul[1] ? {{24{mif.vs2_data[7]}}, mif.vs2_data[7:0]}: mif.vs2_data;
  assign vs3_data = (mif.sew == SEW16)  ? {{16{mif.vs3_data[15]}}, mif.vs3_data[15:0]}: 
                    (mif.sew == SEW8)   ? {{24{mif.vs3_data[7]}}, mif.vs3_data[7:0]}: mif.vs3_data;


  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      start_reg <= '0;
    end else if (mif.decode_done | mul_decode_done_flush) begin
      start_reg <= 0;
    end else if (mif.start_mu) begin
      start_reg <= 1;
    end
  end

  assign stop_flush = mif.stop_flush;
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      mul_decode_done_flush <= '0;
    end else if (stop_flush) begin
      mul_decode_done_flush <= 0;
    end else if (mif.decode_done) begin
      mul_decode_done_flush <= 1;
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
        else if (mif.mul_widen_ena) selected_product = product_low_sew16;
        else selected_product = product_low_sew8;
      SEW16:
        if (mif.high_low) selected_product = product_high_sew16;
        else if (mul_widen_ena_ff2) selected_product = product_low_sew32;
        else selected_product = product_low_sew16;
      SEW32:
        if (mif.high_low) selected_product = product_high_sew32;
        else selected_product = product_low_sew32;
      default:
        selected_product = '0;
    endcase
  end 

endmodule
