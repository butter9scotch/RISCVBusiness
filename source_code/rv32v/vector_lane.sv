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
*   Filename:     vector_lane.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 10/15/2021
*   Description:  Vector lane with multiple functional units
*/

`include "vector_lane_if.vh"

module vector_lane (
  input logic CLK, nRST,
  vector_lane_if vif
);

  import rv32v_types_pkg::*;

  // Instantiate fall functional unit

  arithmetic_unit AU (
    .CLK(CLK),
    .nRST(nRST),
    .aif(vif)
  );

  multiply_unit MULU (
    .CLK(CLK),
    .nRST(nRST),
    .mif(vif)
  );

  divide_unit DIVU (
    .CLK(CLK),
    .nRST(nRST),
    .dif(vif)
  );

  permutation_unit PU (
    .pu_if(vif)
  ); 
  
  mask_unit MU (
    .mu_if(vif)
  ); 

  loadstore_unit LSU (
    .lsif(vif)
  ); 

  logic au, ru, mlu, dv, mau, pu, lu, su, prev_dv, start_reg, done_reg;
  /*always_ff @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      vif.start_div <= 0;
      prev_dv <= 0;
    end else if (vif.start_div) begin
      vif.start_div <= 0;
      prev_dv <= dv;
    end else begin
      prev_dv <= dv;
      if (~prev_dv & dv) 
        vif.start_div <= 1;
    end
  end */

  always_ff @(posedge CLK or negedge nRST) begin
    if (~nRST) begin
      start_reg <= 0;
      done_reg <= 0;
    end else begin
      start_reg <= dv;
      done_reg <= vif.done_du; 
    end
  end 
  assign vif.start_div = (dv ^ start_reg) | (done_reg & dv);

  // Connecting signals
  assign au  = vif.fu_type == ARITH;
  assign ru  = vif.fu_type == RED;
  assign mlu = vif.fu_type == MUL;
  assign dv  = vif.fu_type == DIV;
  assign mau = vif.fu_type == MASK;
  assign pu  = vif.fu_type == PEM;
  assign lu  = vif.fu_type == LOAD_UNIT;
  assign su  = vif.fu_type == STORE_UNIT;
  assign vif.start_mu = mlu;
  // assign vif.start_div = dv;
  assign vif.start_ma = mau;

  
  assign vif.busy_a   = 0;   
  assign vif.busy_p   = 0 ;   //not done yet
  assign vif.busy_m   = iif.busy ;   //
  assign vif.busy_ls  = 0 ;   //single cycle address calculation
  assign vif.exception_p = 0;   //not done yet
  assign vif.exception_m = 0;   //not implemented atm 
  assign vif.exception_ls = 0;   //not done here, remove

  // Output sel
  //busy_mu should not stall entire stage
  assign vif.next_busy = vif.next_busy_mu;
  assign vif.busy        = vif.busy_a | vif.busy_p | vif.busy_m | vif.busy_ls | vif.busy_du;
  //  | vif.busy_mu;
  assign vif.exception   = vif.exception_a | vif.exception_p | vif.exception_m |  vif.exception_du | vif.exception_mu;
  assign vif.lane_result = (au | ru) ? vif.wdata_a :
                           (mlu) ? vif.wdata_mu :
                           (dv) ? vif.wdata_du :
                           (mau) ? vif.wdata_m :
                           (pu) ? vif.wdata_p :
                           (lu | su) ? vif.wdata_ls :
                           32'd0;

endmodule
