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
  vector_lane_if.mask_unit mu_if
);

  import rv32i_types_pkg::*;

  logic [31:0] in1, result, aluresult, encoder_result, constant, anded, add_out, first_element;
  logic [4:0] encoder_out, add_out0, add_out1, add_out2, add_out3;
  logic mask_bit_set;

  assign in1           = mu_if.in_inv ? ~mu_if.vs1_data : mu_if.vs1_data;
  assign aluresult     = mu_if.out_inv ? ~result : result;
  assign first_element = mask_bit_set ? encoder_out : '1; // Return -1 when no mask bit is set
  assign anded         = mu_if.vs2_data & mu_if.mask_32bit;
  assign add_out       = add_out0 + add_out1 + add_out2 + add_out3;
  assign constant      = '1;

  encoder ENC (
    .in(mu_if.vs2_data),
    .ena(mu_if.mask_32bit),
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
    case (mu_if.mask_type)
      VMASK_AND   : mu_if.wdata_m = mu_if.out_inv ? ~(mu_if.vs2_data & in1) : (mu_if.vs2_data & in1);
      VMASK_OR    : mu_if.wdata_m = mu_if.out_inv ? ~(mu_if.vs2_data | in1) : (mu_if.vs2_data | in1);
      VMASK_XOR   : mu_if.wdata_m = mu_if.out_inv ? ~(mu_if.vs2_data ^ in1) : (mu_if.vs2_data ^ in1);
      VMASK_POPC  : mu_if.wdata_m = add_out;
      VMASK_FIRST : mu_if.wdata_m = first_element;
      VMASK_SBF   : mu_if.wdata_m = ~(constant << encoder_out);
      VMASK_SIF   : mu_if.wdata_m = encoder_out == 0 ? 0 : ~(constant << (encoder_out+1));
      VMASK_SOF   : mu_if.wdata_m = encoder_out == 0 ? 0 : 32'd1 << encoder_out;
      VMASK_IOTA  : mu_if.wdata_m = mu_if.iota_res; 
      VMASK_ID    : mu_if.wdata_m = mu_if.offset; 
      default     : mu_if.wdata_m = '0;
    endcase
  end

endmodule
