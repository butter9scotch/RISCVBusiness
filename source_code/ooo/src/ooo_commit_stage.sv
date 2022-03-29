
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
*   Filename:     ooo_commit_stage.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 02/24/2022
*   Description:  Commit stage for the OoO pipeline 
*/

`include "ooo_decode_execute_if.vh"
`include "jump_calc_if.vh"
`include "predictor_pipeline_if.vh"
`include "ooo_hazard_unit_if.vh"
`include "branch_res_if.vh"
`include "cache_control_if.vh"
`include "component_selection_defines.vh"
`include "alu_if.vh"
`include "multiply_unit_if.vh"
`include "divide_unit_if.vh"
`include "loadstore_unit_if.vh"
`include "ooo_execute_commit_if.vh"
`include "completion_buffer_if.vh"

module ooo_commit_stage(
  input logic CLK, nRST,halt,
  ooo_decode_execute_if.execute decode_execute_if,
  ooo_execute_commit_if.commit execute_commit_if,
  ooo_hazard_unit_if.commit hazard_if,
  predictor_pipeline_if.update predict_if,
  completion_buffer_if.writeback cb_if
);

  import rv32i_types_pkg::*;
  import alu_types_pkg::*;
  //import ooo_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  logic illegal_braddr, illegal_jaddr;
  logic valid_pc, latest_valid_pc;
  logic branch_mispredict;
  logic mal_found;
  logic clear_mal;
  logic mal_type; // 1: Load, 0: Store

  assign hazard_if.fault_l      = 1'b0;
  assign hazard_if.mal_l        = mal_type & cb_if.mal_priv;
  assign hazard_if.fault_s      = 1'b0;
  assign hazard_if.mal_s        = ~mal_type & cb_if.mal_priv;
  //assign hazard_if.breakpoint   = execute_commit_if.breakpoint;
  //assign hazard_if.env_m        = execute_commit_if.ecall_insn;
  assign hazard_if.ret          = execute_commit_if.ret_insn;
  assign hazard_if.illegal_insn = execute_commit_if.illegal_insn &  execute_commit_if.invalid_csr; //Illegal Opcode
  assign hazard_if.mal_insn     = execute_commit_if.mal_insn | illegal_jaddr | illegal_braddr; //Instruction not loaded from PC+4
  assign hazard_if.fault_insn   = execute_commit_if.fault_insn; //assigned 1'b0

  //assign hazard_if.badaddr_d    = execute_commit_if.memory_addr;//bad addr -data memory
  assign hazard_if.badaddr_i    = execute_commit_if.pc;// bad addr - instr memory

  // assign hazard_if.epc          = (valid_pc) ? execute_commit_if.pc : latest_valid_pc;
  assign hazard_if.epc = 0;
  assign hazard_if.token        = execute_commit_if.token;
  assign hazard_if.intr_taken   = execute_commit_if.intr_seen;
  assign illegal_jaddr          = (execute_commit_if.jump_instr & (execute_commit_if.jump_addr[1:0] != 2'b00));
  assign illegal_braddr         = (execute_commit_if.branch_instr & (execute_commit_if.br_resolved_addr[1:0] != 2'b00));

  assign valid_pc = (execute_commit_if.opcode != opcode_t'('h0));
  //assign branch_mispredict = hazard_if.mispredict;
  assign branch_mispredict = execute_commit_if.prediction ^ execute_commit_if.branch_taken;

  /*******************************************************
  *** Mal Load Store logic 
  *******************************************************/
  assign clear_mal = execute_commit_if.ret_insn; // TODO: When return from ex
  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        hazard_if.badaddr_d <= '0;
        mal_found <= 0;
        mal_type <= 0;
    end else if (clear_mal) begin
        hazard_if.badaddr_d <= '0;
        mal_found <= '0;
        mal_type <= 0;
    end else if (execute_commit_if.mal_addr & ~mal_found) begin
        hazard_if.badaddr_d <= execute_commit_if.memory_addr;
        mal_found <= 1;
        if (execute_commit_if.wen_ls) begin
            mal_type <= 1;
        end else begin
            mal_type <= 0;
        end
    end
  end

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) 
        latest_valid_pc <= 'h0;
    else begin
        if (halt) 
          latest_valid_pc <= 'h0;
        else if(hazard_if.pc_en & valid_pc) 
            latest_valid_pc  <= execute_commit_if.pc;
      end
  end

  /*******************************************************
  *** Branch predictor update logic 
  *******************************************************/
  assign predict_if.update_predictor = execute_commit_if.branch_instr;
  assign predict_if.prediction       = execute_commit_if.prediction;
  assign predict_if.update_addr      = execute_commit_if.br_resolved_addr;
  assign predict_if.branch_result   = execute_commit_if.branch_taken;
  // assign predict_if.current_pc = execute_commit_if.pc_a;

  /*******************************************************
  *** Write to Completion Buffer logic 
  *******************************************************/
  assign cb_if.index_a     = execute_commit_if.index_a; 
  assign cb_if.wdata_a     = execute_commit_if.exception_a ? execute_commit_if.pc_a : execute_commit_if.jump_instr ? execute_commit_if.pc_a + 4 : execute_commit_if.wdata_au; 
  assign cb_if.vd_a        = execute_commit_if.reg_rd_au; 
  assign cb_if.exception_a = execute_commit_if.exception_a; 
  assign cb_if.ready_a     = (execute_commit_if.ret_insn | execute_commit_if.wen_au | execute_commit_if.branch_instr | execute_commit_if.jump_instr & valid_pc) & execute_commit_if.done_a; 
  assign cb_if.wen_a       = (cb_if.exception_a | execute_commit_if.branch_instr) ? 1'b0 : 1'b1; 

  assign cb_if.index_mu     = execute_commit_if.index_mu; 
  assign cb_if.wdata_mu     = execute_commit_if.exception_mu ? execute_commit_if.pc_mu : execute_commit_if.wdata_mu;  
  assign cb_if.vd_mu        = execute_commit_if.reg_rd_mu; 
  assign cb_if.exception_mu = execute_commit_if.exception_mu; 
  assign cb_if.ready_mu     = execute_commit_if.done_mu; 

  assign cb_if.index_du     = execute_commit_if.index_du; 
  assign cb_if.wdata_du     = execute_commit_if.exception_du ? execute_commit_if.pc_du : execute_commit_if.wdata_du; 
  assign cb_if.vd_du        = execute_commit_if.reg_rd_du; 
  assign cb_if.exception_du = execute_commit_if.exception_du; 
  assign cb_if.ready_du     = execute_commit_if.done_du; 

  assign cb_if.index_ls     = execute_commit_if.index_ls; 
  assign cb_if.wdata_ls     = execute_commit_if.exception_ls ? execute_commit_if.pc_ls : execute_commit_if.wdata_ls; 
  assign cb_if.vd_ls        = execute_commit_if.reg_rd_ls; 
  assign cb_if.exception_ls = execute_commit_if.exception_ls; 
  assign cb_if.ready_ls     = execute_commit_if.done_ls | execute_commit_if.exception_ls; 
  assign cb_if.mal_ls       = execute_commit_if.mal_addr; 
  assign cb_if.halt_instr   = execute_commit_if.halt_instr;
  assign cb_if.wen_ls       = execute_commit_if.wen_ls & ~execute_commit_if.exception_ls;
  //assign cb_if.opcode_commit = execute_commit_if.opcode;

  /*******************************************************
  *** CPU tracker  
  *******************************************************/
  /*always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST ) begin
      cb_if.CPU_TRACKER      <= '0;
    end
    else begin
      if (hazard_if.execute_commit_flush && ~hazard_if.stall_commit || halt ) begin
        cb_if.CPU_TRACKER <= '0;
      end else if(~hazard_if.stall_commit) begin
        cb_if.CPU_TRACKER    <= execute_commit_if.CPU_TRACKER;
      end
    end
  end */

endmodule