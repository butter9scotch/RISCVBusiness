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
*   Filename:     priv_1_12_pma.sv
*
*   Created by:   Hadi Ahmed
*   Email:        ahmed138@purdue.edu
*   Date Created: 04/05/2022
*   Description:  PMA Checker, version 1.12
*/

`include "priv_1_12_internal_if.vh"

module priv_1_12_pma (
  input logic CLK, nRST,
  priv_1_12_internal_if.pma prv_intern_if
);
  import pma_types_1_12_pkg::*;

  pma_reg_t reg_d, reg_i;
  pma_cfg_t cfg_d, cfg_i;

  always_comb begin
    prv_intern_if.pma_l_fault = 1'b0;
    prv_intern_if.pma_s_fault = 1'b0;
    prv_intern_if.pma_i_fault = 1'b0;

    reg_d = prv_intern_if.pma_cfg_regs[prv_intern_if.d_addr[31:26]];
    reg_i = prv_intern_if.pma_cfg_regs[prv_intern_if.i_addr[31:26]];

    if (~prv_intern_if.d_addr[25]) begin
      cfg_d = reg_d.pma_cfg_0;
    end else begin
      cfg_d = reg_d.pma_cfg_1;
    end

    if (~prv_intern_if.i_addr[25]) begin
      cfg_i = reg_i.pma_cfg_0;
    end else begin
      cfg_i = reg_i.pma_cfg_1;
    end

    if (prv_intern_if.ren & ~pma_cfg.R) begin
      prv_intern_if.pma_l_fault = 1'b1;
    end else if (prv_intern_if.wen & ~pma_cfg.W) begin
      prv_intern_if.pma_s_fault = 1'b1;
    end else if (prv_intern_if.xen & ~pma_cfg.X) begin
      prv_intern_if.pma_i_fault = 1'b1;
    end

    // enable this if variable sized access is allowed
    if (prv_intern_if.acc_width_type > pma_cfg.AccWidth) begin
      if (prv_intern_if.ren) begin
        prv_intern_if.pma_l_fault = 1'b1;
      end else if (prv_intern_if.wen) begin
        prv_intern_if.pma_s_fault = 1'b1;
      end else if (prv_intern_if.xen) begin
        prv_intern_if.pma_i_fault = 1'b1;
      end
    end
  end

endmodule
