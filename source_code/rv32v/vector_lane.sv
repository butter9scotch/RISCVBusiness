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

  // Instantiate all functional unit

  arithmetic_unit AU (
    .CLK(CLK),
    .nRST(nRST),
    .au_if(vif)
  );
/*
  permutation_unit PU (
    .CLK(CLK),
    .nRST(nRST),
    .pu_if(vif)
  );
  
  mask_unit MU (
    .mu_if(vif)
  ); */

  load_store_unit LSU (
    .lsu_if(vif)
  ); 

  // Connecting signals
  logic au, ru, mlu, dv, mau, pu, lu, su;
  assign au  = vif.fu_type == ARITH;
  assign ru  = vif.fu_type == RED;
  assign mlu = vif.fu_type == MUL;
  assign dv  = vif.fu_type == DIV;
  assign mau = vif.fu_type == MASK;
  assign pu  = vif.fu_type == PEM;
  assign lu  = vif.fu_type == LOAD_UNIT;
  assign su  = vif.fu_type == STORE_UNIT;

  // Output sel
  assign vif.busy        = vif.busy_a | vif.busy_p | vif.busy_m | vif.busy_ls;
  assign vif.exception   = vif.exception_a | vif.exception_p | vif.exception_m | vif.exception_ls;
  assign vif.lane_result = (au | ru | mlu | dv) ? vif.wdata_a :
                           (mau) ? vif.wdata_m :
                           (pu) ? vif.wdata_p :
                           (lu | su) ? vif.wdata_ls :
                           32'd0;

endmodule
