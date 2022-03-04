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
*   Filename:     tspp_execute_stage.sv
*
*   Created by:   Jacob R. Stevens
*   Email:        steven69@purdue.edu
*   Date Created: 06/16/2016
*   Description:  Execute Stage for the Two Stage Pipeline 
*/

`include "pipe5_mem_writeback_if.vh"
`include "pipe5_forwarding_unit_if.vh"
`include "component_selection_defines.vh"
`include "rv32i_reg_file_if.vh"


module pipe5_writeback_stage(
  input logic CLK, nRST,
  pipe5_mem_writeback_if.writeback mem_wb_if,
  pipe5_forwarding_unit_if.writeback bypass_if,
  rv32i_reg_file_if.writeback rf_if,
  rv32f_reg_file_if.writeback frf_if
);

  import rv32i_types_pkg::*;
  word_t w_data;

  assign bypass_if.WEN_wb      = mem_wb_if.wen;
  assign bypass_if.rd_wb       = mem_wb_if.reg_rd;
 

  assign w_data = (mem_wb_if.w_sel == 'd3) ? mem_wb_if.alu_port_out 
                  : (mem_wb_if.w_sel == 'd0) ? mem_wb_if.dload_ext
                  : (mem_wb_if.w_sel == 'd4) ? mem_wb_if.csr_rdata
                  : mem_wb_if.reg_file_wdata;

  assign bypass_if.rd_data_wb = w_data;
  assign rf_if.wen             = mem_wb_if.wen;     
  assign rf_if.w_data          = w_data;     
  assign rf_if.rd              = mem_wb_if.reg_rd;

  //floating point reg file connections
  assign frf_if.f_wen             = mem_wb_if.f_wen;
  assign frf_if.f_wdata           = (mem_wb_if.f_wsel == 'd0) ?  mem_wb_if.fpu_out : (mem_wb_if.f_wsel == 'd1) ? mem_wb_if.dload_ext : mem_wb_if.f_wdata;
  assign frf_if.f_rd              = mem_wb_if.reg_rd;
endmodule


