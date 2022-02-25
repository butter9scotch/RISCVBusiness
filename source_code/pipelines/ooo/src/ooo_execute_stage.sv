
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
*   Filename:     ooo_execute_stage.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 06/16/2016
*   Description:  Execute Stage for the Out of order pipeline
*/

`include "ooo_decode_execute_if.vh"
`include "ooo_execute_commit_if.vh"
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

module ooo_execute_stage(
  input logic CLK, nRST,halt,
  ooo_decode_execute_if.execute decode_execute_if,
  ooo_execute_comm_if.execute execute_comm_if,
  jump_calc_if.execute jump_if,
  ooo_hazard_unit_if.execute hazard_if,
  branch_res_if.execute branch_if,
  cache_control_if.pipeline cc_if,
  prv_pipeline_if.pipe  prv_pipe_if,
  generic_bus_if dgen_bus_if
);

  import rv32i_types_pkg::*;
  import alu_types_pkg::*;
  import ooo_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  logic csr_reg, csr_pulse;
  word_t csr_rdata;

  // Interface declarations
  arithmetic_unit_if auif();
  multiply_unit_if  mif();
  divide_unit_if    dif();
  loadstore_unit_if lsif();
 
  multiply_unit MULU (.*);
  divide_unit DIVU (.*);
  arithmetic_unit ARITHU (
    .auif(auif)
  );
  loadstore_unit LSU(
    .dgen_bus_if(dgen_bus_if),
    .hazard_if(hazard_if), //this is probably a bad idea? don't pass hazard if through to functional units and also assign in execute stage
    .lsif(lsif)
  );

  assign auif.reg_file_wdata = decode_execute_if.arith.reg_file_wdata;
  assign auif.w_src = decode_execute_if.arith.w_src;
  assign auif.wen = decode_execute_if.arith.wen;
  assign auif.aluop = decode_execute_if.arith.aluop;
  assign auif.port_a = decode_execute_if.arith.port_a;
  assign auif.port_b = decode_execute_if.arith.port_b;
  assign auif.reg_file_wdata = decode_execute_if.arith.reg_file_wdata;      
  assign auif.csr_rdata      = csr_rdata;

  assign hazard_if.busy_au = auif.busy;
  assign hazard_if.busy_mu = mif.busy;
  assign hazard_if.busy_du = dif.busy;
  assign hazard_if.busy_ls = lsif.busy;


    // // input:
    //   // logic:
    //   assign lsif.hazard_pc_en = hazard_if.pc_en;
    //   assign lsif.hazard_intr = hazard_if.intr;
    // // output:
    //   // logic:
    //   assign hazard_if.dren = lsif.hazard_dren;
    //   assign hazard_if.dwen = lsif.hazard_dwen;
    //   assign hazard_if.d_mem_busy = lsif.hazard_d_mem_busy;
    //   assign hazard_if.dflushed = lsif.hazard_dflushed;
    //   assign hazard_if.iflushed = lsif.hazard_iflushed;
    //   assign hazard_if.ifence = lsif.hazard_ifence;

    //   assign hazard_if.fault_l = lsif.hazard_fault_l;
    //   assign hazard_if.mal_l = lsif.hazard_mal_l;
    //   assign hazard_if.fault_s = lsif.hazard_fault_s;
    //   assign hazard_if.mal_s = lsif.hazard_mal_s;
    //   assign hazard_if.mal_insn = lsif.hazard_mal_insn;
    //   assign hazard_if.fault_insn = lsif.hazard_fault_insn;
    //   assign hazard_if.intr_taken = lsif.hazard_intr_taken;
    //   // word_t:

    //   assign hazard_if.badaddr_d = lsif.hazard_badaddr_d;
    //   assign hazard_if.badaddr_i = lsif.hazard_badaddr_i;





  logic [1:0] byte_offset;
  logic [3:0] byte_en_standard;
  word_t w_data, alu_port_b, alu_port_a;
  word_t updated_rs1_data, updated_rs2_data;
  word_t csr_wdata;
  logic intr_taken_ex;
  word_t branch_addr, resolved_addr;


  // assign alu_if.port_a = alu_port_a;
  // assign alu_if.port_b = alu_port_b;
  // assign alu_if.aluop  = decode_execute_if.alu.aluop;



//============================MULTIPLY==============================


  assign mif.rs1_data = decode_execute_if.divide.rs1_data;
  assign mif.rs2_data = decode_execute_if.divide.rs2_data;
  assign mif.start_mu = decode_execute_if.multiply.start_mu;
  assign mif.high_low_sel = decode_execute_if.multiply.high_low_sel;
  assign mif.is_signed = decode_execute_if.multiply.is_signed;
  assign mif.decode_done = decode_execute_if.multiply.decode_done;

//=============================DIVIDE===============================

  assign dif.rs1_data = decode_execute_if.divide.rs1_data;
  assign dif.rs2_data = decode_execute_if.divide.rs2_data;    
  assign dif.start_div = decode_execute_if.divide.start_div;
  assign dif.div_type = decode_execute_if.divide.div_type;
  assign dif.is_signed_div = decode_execute_if.divide.is_signed_div;


   //NEED CSR ENA SIGNAL
  assign csr_wdata = (decode_execute_if.csr_imm) ? decode_execute_if.csr_imm_value : decode_execute_if.port_a;


   //Keep polling interrupt. This is so that interrupt can be latched even if the processor is busy doing something 
  always_ff @(posedge CLK, negedge nRST) begin :INTERRUPT
      if (~nRST) begin
          intr_taken_ex <= 1'b0;
      end
      else begin
        if (halt) begin
            intr_taken_ex <= 1'b0;
        end
        else if (hazard_if.intr) begin
            intr_taken_ex <= 1'b1;
        end
        else if (hazard_if.intr_taken) begin
            intr_taken_ex <= 1'b0;
        end
    end
  end

    /*******************************************************
  *** CSR / Priv Interface Logic 
  *******************************************************/ 
  assign hazard_if.csr     = decode_execute_if.csr_instr;
  assign prv_pipe_if.swap  = decode_execute_if.csr_swap;
  assign prv_pipe_if.clr   = decode_execute_if.csr_clr;
  assign prv_pipe_if.set   = decode_execute_if.csr_set;
  assign prv_pipe_if.wdata = csr_wdata;
  assign prv_pipe_if.addr  = decode_execute_if.csr_addr;
  assign prv_pipe_if.valid_write = (prv_pipe_if.swap | prv_pipe_if.clr | prv_pipe_if.set); //TODO add to latch
  assign prv_pipe_if.instr = (decode_execute_if.instr != '0);
  assign hazard_if.csr_pc = decode_execute_if.pc;
   
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
      csr_reg <= 1'b0;
    else 
      csr_reg <= decode_execute_if.csr_instr;
  end
  
  assign csr_pulse = decode_execute_if.csr_instr && ~csr_reg;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
        csr_rdata <= 'h0;
    else if (csr_pulse)
        csr_rdata <= prv_pipe_if.rdata;
  end


  //Forwading logic
  assign hazard_if.load   = decode_execute_if.dren;
  
  /*******************************************************
  *** Jumps
  *******************************************************/ 
  assign jump_if.base   = (decode_execute_if.j_sel)? decode_execute_if.pc : updated_rs1_data;
  assign jump_if.offset = decode_execute_if.j_offset;
  assign jump_if.j_sel  = decode_execute_if.j_sel;

  logic jump_instr;
  assign jump_instr = decode_execute_if.jump_instr;
  assign execute_comm_if.jump_addr  = jump_if.jump_addr;

    /*******************************************************
  *** Branch Target Resolution and Associated Logic 
  *******************************************************/
  
  assign hazard_if.brj_addr   = ( jump_instr) ? decode_execute_if.jump_addr : decode_execute_if.br_resolved_addr;
  assign hazard_if.mispredict = decode_execute_if.prediction ^ decode_execute_if.branch_taken;
  assign hazard_if.branch     = decode_execute_if.branch_instr; 
  assign hazard_if.jump       = decode_execute_if.jump_instr; 

  assign branch_if.rs1_data    = updated_rs1_data;
  assign branch_if.rs2_data    = updated_rs2_data;
  assign branch_if.pc          = decode_execute_if.pc;
  assign branch_if.imm_sb      = decode_execute_if.br_imm_sb;
  assign branch_if.branch_type = decode_execute_if.br_branch_type;

  assign branch_addr  = branch_if.branch_addr;
  assign resolved_addr = branch_if.branch_taken ? branch_addr : decode_execute_if.pc4;

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST ) begin
      execute_comm_if.arith_wen          <= '0;
      execute_comm_if.mul_wen            <= '0;
      execute_comm_if.div_wen            <= '0;
      execute_comm_if.loadstore_wen      <= '0;

      execute_comm_if.wdata_au           <= '0;
      execute_comm_if.wdata_mu           <= '0;
      execute_comm_if.wdata_du           <= '0;
      execute_comm_if.wdata_ls           <= '0;
          
      execute_comm_if.dren <= '0;
      execute_comm_if.mal_addr <= '0;
      execute_comm_if.dwen <= '0;
      execute_comm_if.breakpoint <= '0;
      execute_comm_if.ecall_insn <= '0;
      execute_comm_if.ret_insn <= '0;
      execute_comm_if.illegal_insn <= '0;
      execute_comm_if.invalid_csr <= '0;
      execute_comm_if.mal_insn <= '0;
      execute_comm_if.fault_insn <= '0;
      execute_comm_if.memory_addr <= '0;
      execute_comm_if.pc <= '0;
      execute_comm_if.token <= '0;
      execute_comm_if.intr_seen <= '0;
      execute_comm_if.jump_instr <= '0;
      execute_comm_if.jump_addr <= '0;
      execute_comm_if.branch_instr <=   '0;
      execute_comm_if.br_resolved_addr <=   '0;

      //Branch predict
      execute_comm_if.branch_instr      <= '0;
      execute_comm_if.prediction        <= '0;
      execute_comm_if.br_resolved_addr  <= '0;
      execute_comm_if.branch_taken      <= '0;

      //Halt
      execute_comm_if.halt_instr         <= '0;
      //CPU tracker
      execute_comm_if.funct3             <= '0;
      execute_comm_if.funct12            <= '0;
      execute_comm_if.imm_S              <= '0; 
      execute_comm_if.imm_I              <= '0; 
      execute_comm_if.imm_U              <= '0;
      execute_comm_if.imm_UJ_ext         <= '0;
      execute_comm_if.imm_SB             <= '0;
      execute_comm_if.instr_30           <= '0;
      execute_comm_if.rs1                <= '0;
      execute_comm_if.rs2                <= '0;
    end
    else begin
        if (hazard_if.ex_mem_flush && hazard_if.pc_en || halt ) begin
          execute_comm_if.arith_wen          <= '0;
          execute_comm_if.mul_wen            <= '0;
          execute_comm_if.div_wen            <= '0;
          execute_comm_if.loadstore_wen      <= '0;

          execute_comm_if.wdata_au           <= '0;
          execute_comm_if.wdata_mu           <= '0;
          execute_comm_if.wdata_du           <= '0;
          execute_comm_if.wdata_ls           <= '0;
          
          execute_comm_if.busy_au <= '0;
          execute_comm_if.busy_mu <= '0;
          execute_comm_if.busy_du <= '0;
          execute_comm_if.busy_ls <= '0;

          execute_comm_if.dren <= '0;
          execute_comm_if.mal_addr <= '0;
          execute_comm_if.dwen <= '0;
          execute_comm_if.breakpoint <= '0;
          execute_comm_if.ecall_insn <= '0;
          execute_comm_if.ret_insn <= '0;
          execute_comm_if.illegal_insn <= '0;
          execute_comm_if.invalid_csr <= '0;
          execute_comm_if.mal_insn <= '0;
          execute_comm_if.fault_insn <= '0;
          execute_comm_if.memory_addr <= '0;
          execute_comm_if.pc <= '0;
          execute_comm_if.token <= '0;
          execute_comm_if.intr_seen <= '0;
          execute_comm_if.jump_instr <= '0;
          execute_comm_if.jump_addr <= '0;
          execute_comm_if.branch_instr <=   '0;
          execute_comm_if.br_resolved_addr <=   '0;

          //Branch predict
          execute_comm_if.branch_instr      <= '0;
          execute_comm_if.prediction        <= '0;
          execute_comm_if.br_resolved_addr  <= '0;
          execute_comm_if.branch_taken      <= '0;

          //Halt
          execute_comm_if.halt_instr         <= '0;
          //CPU tracker
          execute_comm_if.funct3             <= '0;
          execute_comm_if.funct12            <= '0;
          execute_comm_if.imm_S              <= '0; 
          execute_comm_if.imm_I              <= '0; 
          execute_comm_if.imm_U              <= '0;
          execute_comm_if.imm_UJ_ext         <= '0;
          execute_comm_if.imm_SB             <= '0;
          execute_comm_if.instr_30           <= '0;
          execute_comm_if.rs1                <= '0;
          execute_comm_if.rs2                <= '0;
        end else if(hazard_if.pc_en ) begin
          //Writeback
          execute_comm_if.wen_au          <= auif.wen;
          execute_comm_if.wen_mu            <= mif.wen;
          execute_comm_if.wen_du            <= dif.wen;
          execute_comm_if.wen_ls      <= lsif.wen;

          execute_comm_if.wdata_au           <= auif.wdata_au;
          execute_comm_if.wdata_mu           <= mif.wdata_mu;
          execute_comm_if.wdata_du           <= dif.wdata_du;
          execute_comm_if.wdata_ls           <= lsif.wdata_ls;
          
          execute_comm_if.reg_rd_au <= auif.reg_rd;
          execute_comm_if.reg_rd_mu <= mif.reg_rd;
          execute_comm_if.reg_rd_du <= dif.reg_rd;
          execute_comm_if.reg_rd_ls <= lsif.reg_rd;

          execute_comm_if.dren <= lsif.dren;
          execute_comm_if.mal_addr <= decode_execute_if.mal_addr;
          execute_comm_if.dwen <= lsif.dwen;
          execute_comm_if.breakpoint <= decode_execute_if.breakpoint;
          execute_comm_if.ecall_insn <= decode_execute_if.ecall_insn;
          execute_comm_if.ret_insn <= decode_execute_if.ret_insn;
          execute_comm_if.illegal_insn <= decode_execute_if.illegal_insn;
          execute_comm_if.invalid_csr <= prv_pipe_if.invalid_csr;
          execute_comm_if.mal_insn <= decode_execute_if.mal_insn;
          execute_comm_if.fault_insn <= decode_execute_if.fault_insn;
          execute_comm_if.memory_addr <= lsif.memory_addr;
          execute_comm_if.pc <= decode_execute_if.pc;
          execute_comm_if.token <= 0;
          execute_comm_if.intr_seen <= intr_taken_ex; //TODO
          execute_comm_if.jump_instr <= decode_execute_if.jump_instr;
          execute_comm_if.jump_addr <= jump_if.jump_addr;
          execute_comm_if.branch_instr <=   branch_addr;
          execute_comm_if.br_resolved_addr <=   resolved_addr;

          //Branch predict
          execute_comm_if.branch_instr      <= decode_execute_if.branch_instr;
          execute_comm_if.prediction        <= decode_execute_if.prediction;
          execute_comm_if.br_resolved_addr  <= decode_execute_if.br_resolved_addr;
          execute_comm_if.branch_taken      <= decode_execute_if.branch_taken;

          //Halt
          execute_comm_if.halt_instr         <= decode_execute_if.halt_instr;
          //CPU tracker
          execute_comm_if.funct3             <= decode_execute_if.funct3;
          execute_comm_if.funct12            <= decode_execute_if.funct12;
          execute_comm_if.imm_S              <= decode_execute_if.imm_S; 
          execute_comm_if.imm_I              <= decode_execute_if.imm_I; 
          execute_comm_if.imm_U              <= decode_execute_if.imm_U;
          execute_comm_if.imm_UJ_ext         <= decode_execute_if.imm_UJ_ext;
          execute_comm_if.imm_SB             <= decode_execute_if.imm_SB;
          execute_comm_if.instr_30           <= decode_execute_if.instr_30;
          execute_comm_if.rs1                <= decode_execute_if.reg_rs1;
          execute_comm_if.rs2                <= decode_execute_if.reg_rs2;


         end
      end
  end

endmodule
