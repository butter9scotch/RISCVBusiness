
/*
*   Copyright 2016 Purdue University
*   
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*   
*       http://www.apache.org/licenses/LICENSE-2.0
*   a
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*
*
*   Filename:     pipe5_commit_stage.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 02/24/2022
*   Description:  Commit stage for the OoO pipeline 
*/

`include "pipe5_decode_execute_if.vh"
`include "pipe5_execute_mem_if.vh"
`include "jump_calc_if.vh"
`include "predictor_pipeline_if.vh"
`include "pipe5_hazard_unit_if.vh"
`include "branch_res_if.vh"
`include "cache_control_if.vh"
`include "component_selection_defines.vh"
`include "alu_if.vh"
`include "multiply_unit_if.vh"
`include "divide_unit_if.vh"
`include "loadstore_unit_if.vh"

module pipe5_commit_stage(
  input logic CLK, nRST,halt,
  pipe5_decode_execute_if.execute decode_execute_if,
  pipe5_execute_commit_if.commit execute_comm_if,
  pipe5_hazard_unit_if.commit hazard_if,
  predictor_pipeline_if.update predict_if,
);

  import rv32i_types_pkg::*;
  import alu_types_pkg::*;
  import pipe5_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  logic illegal_braddr, illegal_jaddr;
  logic valid_pc;

  assign hazard_if.fault_l      =  1'b0; 
  assign hazard_if.mal_l        =  execute_comm_if.dren & execute_comm_if.mal_addr;
  assign hazard_if.fault_s      =  1'b0;
  assign hazard_if.mal_s        =  execute_comm_if.dwen & execute_comm_if.mal_addr;
  assign hazard_if.breakpoint   =  execute_comm_if.breakpoint;
  assign hazard_if.env_m        =  execute_comm_if.ecall_insn;
  assign hazard_if.ret          =  execute_comm_if.ret_insn;
  assign hazard_if.illegal_insn =  execute_comm_if.illegal_insn &  execute_comm_if.invalid_csr; //Illegal Opcode
  assign hazard_if.mal_insn     =  execute_comm_if.mal_insn | illegal_jaddr | illegal_braddr; //Instruction not loaded from PC+4
  assign hazard_if.fault_insn   =  execute_comm_if.fault_insn; //assigned 1'b0

  assign hazard_if.badaddr_d    =  execute_comm_if.memory_addr;//bad addr -data memory
  assign hazard_if.badaddr_i    =  execute_comm_if.pc;// bad addr - instr memory

  assign hazard_if.epc          =  (valid_pc) ? execute_comm_if.pc : latest_valid_pc;
  assign hazard_if.token        =  execute_comm_if.token; 
  assign hazard_if.intr_taken   =  execute_comm_if.intr_seen ;
  assign illegal_jaddr = (execute_comm_if.jump_instr & (execute_comm_if.jump_addr[1:0] != 2'b00));
  assign illegal_braddr = (execute_comm_if.branch_instr & (execute_comm_if.br_resolved_addr[1:0] != 2'b00));

  assign valid_pc = (execute_mem_if.opcode != opcode_t'('h0));

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) 
          latest_valid_pc <= 'h0;
    else begin
        if (halt) 
          latest_valid_pc <= 'h0;
        else if(hazard_if.pc_en & valid_pc) 
            latest_valid_pc  <= execute_comm_if.pc;
      end
  end

  /*******************************************************
  *** Branch predictor update logic 
  *******************************************************/
  assign predict_if.update_predictor = execute_comm_if.branch_instr;
  assign predict_if.prediction       = execute_comm_if.prediction;
  assign predict_if.update_addr      = execute_comm_if.br_resolved_addr;
  assign predict_if.branch_result   = execute_comm_if.branch_taken;

endmodule