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
*   Filename:     RISCVBusiness.sv
*   
*   Created by:   John Skubic
*   Email:        jskubic@purdue.edu
*   Date Created: 06/01/2016
*   Description:  Top level module for RISCVBusiness
*/

`include "generic_bus_if.vh"
`include "ahb_if.vh"
`include "component_selection_defines.vh"
//`include "risc_mgmt_if.vh"
`include "cache_control_if.vh"
//`include "sparce_pipeline_if.vh"
`include "core_interrupt_if.vh"
`include "ooo_fetch1_fetch2_if.vh"
`include "ooo_fetch2_decode_if.vh"
`include "ooo_decode_execute_if.vh"
`include "ooo_execute_commit_if.vh"
`include "completion_buffer_if.vh"
`include "ooo_hazard_unit_if.vh"
`include "jump_calc_if.vh"
`include "branch_res_if.vh"
`include "rv32i_reg_file_if.vh"
`include "predictor_pipeline_if.vh"
`include "generic_bus_if.vh"
`include "prv_pipeline_if.vh"

module RISCVBusiness (
  input logic CLK, nRST,
  output logic wfi,
  core_interrupt_if.core interrupt_if,
  `ifdef BUS_INTERFACE_GENERIC_BUS
  generic_bus_if.cpu gen_bus_if
  `elsif BUS_INTERFACE_AHB
  ahb_if.ahb_m ahb_master
  `endif
);

  import rv32i_types_pkg::*;
 //  Interface instantiations

  generic_bus_if icache_gen_bus_if();
  generic_bus_if dcache_gen_bus_if();
  generic_bus_if icache_mc_if();
  generic_bus_if dcache_mc_if();
  generic_bus_if pipeline_trans_if(); 
  //risc_mgmt_if   rm_if();
  predictor_pipeline_if predict_if();
  prv_pipeline_if prv_pipe_if();
  cache_control_if cc_if();
  //sparce_pipeline_if sparce_if();

  ooo_fetch1_fetch2_if fetch1_fetch2_if();
  ooo_fetch2_decode_if fetch_decode_if();
  ooo_decode_execute_if decode_execute_if();
  ooo_execute_commit_if execute_commit_if();
  ooo_hazard_unit_if hazard_if();
  rv32i_reg_file_if rf_if();
  jump_calc_if jump_if();
  branch_res_if branch_if();
  completion_buffer_if cb_if();
  logic halt;    //JOHN CHANGED THIS

   ooo_fetch1_stage fetch1_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.halt(halt)
       ,.fetch1_fetch2_if(fetch1_fetch2_if)
       ,.predict_if(predict_if)
       ,.hazard_if(hazard_if)
      );

   ooo_fetch2_stage fetch2_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.halt(halt)
       ,.fetch1_fetch2_if(fetch1_fetch2_if)
       ,.fetch_decode_if(fetch_decode_if)
       ,.igen_bus_if(icache_gen_bus_if)
       ,.hazard_if(hazard_if)
      );

   ooo_decode_stage decode_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.halt(halt)
       ,.fetch_decode_if(fetch_decode_if)
       ,.decode_execute_if(decode_execute_if)
       ,.rf_if(rf_if)
       ,.hazard_if(hazard_if)
       ,.cc_if(cc_if)
      );

   ooo_execute_stage execute_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.halt(halt)
       ,.decode_execute_if(decode_execute_if)
       ,.execute_commit_if(execute_commit_if)
       ,.jump_if(jump_if)
       ,.hazard_if(hazard_if)
       ,.branch_if(branch_if)
       ,.cc_if(cc_if)
       ,.prv_pipe_if(prv_pipe_if)
       ,.dgen_bus_if(gen_bus_if)
      );

   ooo_commit_stage commit_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.halt(halt)
       ,.decode_execute_if(decode_execute_if)
       ,.execute_commit_if(execute_commit_if)
       ,.hazard_if(hazard_if)
       ,.predict_if(predict_if)
       ,.cb_if(cb_if)
      );
   
   rv32i_reg_file reg_file (.*);

   ooo_hazard_unit hazard_unit (
       .hazard_if(hazard_if)
       ,.prv_pipe_if(prv_pipe_if)
     );
   
   always @(posedge CLK, negedge nRST)
   begin
       if (!nRST)
           halt <= 1'b0;
       else if (mem_wb_if.halt_instr)
           halt <= 1'b1;

   end

  branch_predictor_wrapper branch_predictor_i (
    .CLK(CLK),
    .nRST(nRST),
    .predict_if(predict_if)
  );

  priv_wrapper priv_wrapper_i (
    .CLK(CLK),
    .nRST(nRST),
    .prv_pipe_if(prv_pipe_if),
    .interrupt_if
  );


  /*risc_mgmt_wrapper rmgmt (
    .CLK(CLK),
    .nRST(nRST),
    .rm_if(rm_if)
  );*/

  separate_caches sep_caches (
    .CLK(CLK),
    .nRST(nRST),
    .icache_proc_gen_bus_if(icache_gen_bus_if),
    .icache_mem_gen_bus_if(icache_mc_if),
    .dcache_proc_gen_bus_if(dcache_gen_bus_if),
    .dcache_mem_gen_bus_if(dcache_mc_if),
    .cc_if(cc_if)
  );

  memory_controller mc (
    .CLK(CLK),
    .nRST(nRST),
    .d_gen_bus_if(dcache_mc_if),
    .i_gen_bus_if(icache_mc_if),
    .out_gen_bus_if(pipeline_trans_if)
  );

  /*sparce_wrapper sparce_wrapper_i (
    .CLK(CLK),
    .nRST(nRST),
    .sparce_if(sparce_if)
<<<<<<< HEAD
  );

  rv32c_wrapper rv32c (
    .CLK(CLK),
    .nRST(nRST),
    .rv32cif(rv32cif)
  );

  // Instantiate the chosen bus interface
=======
  ); */

  generate 
    case (BUS_INTERFACE_TYPE) 
      "generic_bus_if" : begin
        generic_nonpipeline bt(
          .CLK(CLK), 
          .nRST(nRST), 
          .pipeline_trans_if(pipeline_trans_if), 
          .out_gen_bus_if(gen_bus_if)
        );
      end
      "ahb_if" : begin 
        ahb bt (
          .CLK(CLK),
          .nRST(nRST),
          .out_gen_bus_if(pipeline_trans_if),
          .ahb_m(ahb_master)
        ); 
      end
   endcase

  endgenerate

endmodule
