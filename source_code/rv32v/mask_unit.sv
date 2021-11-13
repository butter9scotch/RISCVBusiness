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
*   Filename:     mask_unit.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 11/13/2021
*   Description:  Support mask operation
*/

`include "vector_lane_if.vh"

module mask_unit (
  vector_lane_if.mask_unit mif
);

  import rv32v_types_pkg::*;

  logic [31:0] in1, result, aluresult, encoder_result, constant, anded, add_out, first_element, iota_out;
  logic [4:0] encoder_out, add_out0, add_out1, add_out2, add_out3;
  logic mask_bit_set;

  assign in1           = mif.in_inv ? ~mif.vs1_data : mif.vs1_data;
  assign aluresult     = mif.out_inv ? ~result : result;
  assign first_element = mask_bit_set ? encoder_out : '1; // Return -1 when no mask bit is set
  assign anded         = mif.vs2_data & mif.mask_32bit;
  assign add_out       = add_out0 + add_out1 + add_out2 + add_out3;
  assign constant      = '1;

  encoder ENC (
    .in(mif.vs2_data),
    .ena(mif.mask_32bit),
    .strobe(mask_bit_set), // 0: No mask bit is set
    .out(encoder_out)
  );

  tree_adder_8bit TA0 (
    .add_in(anded[7:0]),
    .add_out(add_out0)
  );

  tree_adder_8bit TA1 (
    .add_in(anded[15:8]),
    .add_out(add_out1)
  );

  tree_adder_8bit TA2 (
    .add_in(anded[23:16]),
    .add_out(add_out2)
  );

  tree_adder_8bit TA3 (
    .add_in(anded[31:24]),
    .add_out(add_out3)
  );

  always_comb begin 
    case (mif.mask_type)
      VMASK_AND   : mif.wdata_m = mif.vs2_data & in1;
      VMASK_OR    : mif.wdata_m = mif.vs2_data | in1;
      VMASK_XOR   : mif.wdata_m = mif.vs2_data ^ in1;
      VMASK_POPC  : mif.wdata_m = add_out;
      VMASK_FIRST : mif.wdata_m = first_element;
      VMASK_SBF   : mif.wdata_m = ~(constant << encoder_out);
      VMASK_SIF   : mif.wdata_m = ~(constant << (encoder_out+1));
      VMASK_SOF   : mif.wdata_m = 32'd1 << encoder_out;
      VMASK_IOTA  : mif.wdata_m = iota_out; // TODO: Add logics
      default     : mif.wdata_m = '0;
    endcase
  end

endmodule
