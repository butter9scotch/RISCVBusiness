
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
  ooo_execute_commit_if.execute execute_commit_if,
  jump_calc_if.execute jump_if,
  ooo_hazard_unit_if.execute hazard_if,
  branch_res_if.execute branch_if,
  cache_control_if.pipeline cc_if,
  prv_pipeline_if.pipe  prv_pipe_if,
  generic_bus_if.cpu dgen_bus_if
);

  import rv32i_types_pkg::*;
  import alu_types_pkg::*;
  //import ooo_types_pkg::*;
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
    .CLK(CLK),
    .nRST(nRST),
    .halt(halt), 
    .dgen_bus_if(dgen_bus_if),
    .hazard_if(hazard_if), //this is probably a bad idea? don't pass hazard if through to functional units and also assign in execute stage
    .lsif(lsif)
  );

  logic [1:0] byte_offset;
  logic [3:0] byte_en_standard;
  word_t w_data, alu_port_b, alu_port_a;
  word_t updated_rs1_data, updated_rs2_data;
  word_t csr_wdata;
  logic intr_taken_ex;
  word_t branch_addr, resolved_addr;

  assign auif.reg_file_wdata  = decode_execute_if.arith.reg_file_wdata;
  assign auif.w_src           = decode_execute_if.arith.w_src;
  assign auif.wen             = decode_execute_if.arith.wen;
  assign auif.aluop           = decode_execute_if.arith.aluop;
  assign auif.port_a          = decode_execute_if.arith.port_a;
  assign auif.port_b          = decode_execute_if.arith.port_b;
  assign auif.reg_file_wdata  = decode_execute_if.arith.reg_file_wdata;
  assign auif.csr_rdata       = csr_rdata;

  assign hazard_if.busy_au = auif.busy;
  assign hazard_if.busy_mu = mif.busy;
  assign hazard_if.busy_du = dif.busy;
  assign hazard_if.busy_ls = lsif.busy;



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
  assign jump_if.base   = (decode_execute_if.JUMP_STRUCT.j_sel)? 
                          decode_execute_if.pc : updated_rs1_data;
  assign jump_if.offset =  decode_execute_if.JUMP_STRUCT.j_offset;
  assign jump_if.j_sel  =  decode_execute_if.JUMP_STRUCT.j_sel;

  logic jump_instr;
  assign jump_instr = decode_execute_if.JUMP_STRUCT.jump_instr;
  assign execute_commit_if.jump_addr  = jump_if.JUMP_STRUCT.jump_addr;

  /*******************************************************
  *** Branch Target Resolution and Associated Logic 
  *******************************************************/

  assign hazard_if.brj_addr   = ( jump_instr) ? decode_execute_if.JUMP_STRUCT.jump_addr : 
                                                decode_execute_if.BRANCH_STRUCT.br_resolved_addr;
  assign hazard_if.mispredict = decode_execute_if.prediction ^ branch_if.branch_taken;
  assign hazard_if.branch     = decode_execute_if.branch_instr; 
  assign hazard_if.jump       = decode_execute_if.jump_instr; 

  assign branch_if.rs1_data    = updated_rs1_data;
  assign branch_if.rs2_data    = updated_rs2_data;
  assign branch_if.pc          = decode_execute_if.BRANCH_STRUCT.pc;
  assign branch_if.imm_sb      = decode_execute_if.BRANCH_STRUCT.br_imm_sb;
  assign branch_if.branch_type = decode_execute_if.BRANCH_STRUCT.br_branch_type;

  assign branch_addr  = branch_if.branch_addr;
  assign resolved_addr = branch_if.branch_taken ? branch_addr : decode_execute_if.BRANCH_STRUCT.pc4;

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST ) begin
      //WRITEBACK Signals:
      //ARITHMETIC
      execute_commit_if.wen_au           <= '0;
      execute_commit_if.wdata_au         <= '0;
      execute_commit_if.reg_rd_au        <= '0;
      //MULTIPLY
      execute_commit_if.wen_mu           <= '0;
      execute_commit_if.wdata_mu         <= '0;
      execute_commit_if.reg_rd_mu        <= '0;
      //DIVIDE
      execute_commit_if.wen_du           <= '0;
      execute_commit_if.wdata_du         <= '0;
      execute_commit_if.reg_rd_du        <= '0;
      //LOADSTORE
      execute_commit_if.wen_ls           <= '0;
      execute_commit_if.wdata_ls         <= '0;
      execute_commit_if.reg_rd_ls        <= '0;
      execute_commit_if.opcode           <= '0;
      execute_commit_if.dren             <= '0;
      execute_commit_if.dwen             <= '0;
      //EXECUTE
      execute_commit_if.mal_addr         <= '0;
      execute_commit_if.breakpoint       <= '0;
      execute_commit_if.ecall_insn       <= '0;
      execute_commit_if.ret_insn         <= '0;
      execute_commit_if.illegal_insn     <= '0;
      execute_commit_if.invalid_csr      <= '0;
      execute_commit_if.mal_insn         <= '0;
      execute_commit_if.fault_insn       <= '0;
      execute_commit_if.memory_addr      <= '0;
      execute_commit_if.pc               <= '0;
      execute_commit_if.token            <= '0;
      execute_commit_if.intr_seen        <= '0;
      execute_commit_if.jump_instr       <= '0;
      execute_commit_if.jump_addr        <= '0;
      execute_commit_if.branch_instr     <= '0;
      execute_commit_if.br_resolved_addr <= '0;
      //BRANCH PREDICTOR UPDATE
      execute_commit_if.branch_instr      <= '0;
      execute_commit_if.branch_taken      <= '0;
      execute_commit_if.prediction        <= '0;
      execute_commit_if.br_resolved_addr  <= '0;
      execute_commit_if.pc                <= '0;
      execute_commit_if.pc4               <= '0;
      //Halt
      execute_commit_if.halt_instr       <= '0;
      //CPU tracker
      execute_commit_if.CPU_TRACKER <= '0;
    end
    else begin
      if (hazard_if.ex_mem_flush && hazard_if.pc_en || halt ) begin
        //WRITEBACK Signals:
        //ARITHMETIC
        execute_commit_if.wen_au           <= '0;
        execute_commit_if.wdata_au         <= '0;
        execute_commit_if.reg_rd_au        <= '0;
        //MULTIPLY
        execute_commit_if.wen_mu           <= '0;
        execute_commit_if.wdata_mu         <= '0;
        execute_commit_if.reg_rd_mu        <= '0;
        //DIVIDE
        execute_commit_if.wen_du           <= '0;
        execute_commit_if.wdata_du         <= '0;
        execute_commit_if.reg_rd_du        <= '0;
        //LOADSTORE
        execute_commit_if.wen_ls           <= '0;
        execute_commit_if.wdata_ls         <= '0;
        execute_commit_if.reg_rd_ls        <= '0;
        execute_commit_if.opcode           <= '0;
        execute_commit_if.dren             <= '0;
        execute_commit_if.dwen             <= '0;
        //EXCEPTION
        execute_commit_if.mal_addr         <= '0;
        execute_commit_if.breakpoint       <= '0;
        execute_commit_if.ecall_insn       <= '0;
        execute_commit_if.ret_insn         <= '0;
        execute_commit_if.illegal_insn     <= '0;
        execute_commit_if.invalid_csr      <= '0;
        execute_commit_if.mal_insn         <= '0;
        execute_commit_if.fault_insn       <= '0;
        execute_commit_if.memory_addr      <= '0;
        execute_commit_if.pc               <= '0;
        execute_commit_if.token            <= '0;
        execute_commit_if.intr_seen        <= '0;
        execute_commit_if.jump_instr       <= '0;
        execute_commit_if.jump_addr        <= '0;
        execute_commit_if.branch_instr     <= '0;
        execute_commit_if.br_resolved_addr <= '0;
        //BRANCH PREDICTOR UPDATE
        execute_commit_if.branch_instr      <= '0;
        execute_commit_if.branch_taken      <= '0;
        execute_commit_if.prediction        <= '0;
        execute_commit_if.br_resolved_addr  <= '0;
        execute_commit_if.pc                <= '0;
        execute_commit_if.pc4               <= '0;
        //Halt
        execute_commit_if.halt_instr       <= '0;
        //CPU tracker
        execute_commit_if.CPU_TRACKER <= '0;
      end else if(hazard_if.pc_en ) begin
        //WRITEBACK Signals:
        //ARITHMETIC
        execute_commit_if.wen_au                 <= auif.wen;
        execute_commit_if.wdata_au               <= auif.wdata_au;
        execute_commit_if.reg_rd_au              <= auif.reg_rd;
        //MULTIPLY
        execute_commit_if.wen_mu                 <= mif.wen;
        execute_commit_if.wdata_mu               <= mif.wdata_mu;
        execute_commit_if.reg_rd_mu              <= mif.reg_rd;
        //DIVIDE
        execute_commit_if.wen_du                 <= dif.wen;
        execute_commit_if.wdata_du               <= dif.wdata_du;
        execute_commit_if.reg_rd_du              <= dif.reg_rd;
        //LOADSTORE
        execute_commit_if.wen_ls                 <= lsif.wen;
        execute_commit_if.wdata_ls               <= lsif.wdata_ls;
        execute_commit_if.reg_rd_ls              <= lsif.reg_rd;
        execute_commit_if.opcode                 <= decode_execute_if.loadstore.opcode;
        execute_commit_if.dren                   <= lsif.dren_ls;
        execute_commit_if.dwen                   <= lsif.dwen_ls;
        //EXCEPTION
        execute_commit_if.mal_addr               <= decode_execute_if.EXCEPTION.mal_addr;
        execute_commit_if.breakpoint             <= decode_execute_if.EXCEPTION.breakpoint;
        execute_commit_if.ecall_insn             <= decode_execute_if.EXCEPTION.ecall_insn;
        execute_commit_if.ret_insn               <= decode_execute_if.EXCEPTION.ret_insn;
        execute_commit_if.illegal_insn           <= decode_execute_if.EXCEPTION.illegal_insn;
        execute_commit_if.invalid_csr            <= prv_pipe_if.invalid_csr;
        execute_commit_if.mal_insn               <= decode_execute_if.EXCEPTION.mal_insn;
        execute_commit_if.fault_insn             <= decode_execute_if.EXCEPTION.fault_insn;
        execute_commit_if.memory_addr            <= lsif.memory_addr;
        execute_commit_if.pc                     <= decode_execute_if.arith.pc;
        execute_commit_if.token                  <= 0;
        execute_commit_if.intr_seen              <= intr_taken_ex; //TODO
        execute_commit_if.jump_instr             <= decode_execute_if.JUMP_STRUCT.jump_instr;
        execute_commit_if.jump_addr              <= jump_if.jump_addr;
        execute_commit_if.branch_instr           <= branch_addr;
        execute_commit_if.br_resolved_addr       <= resolved_addr;
        //BRANCH PREDICTOR UPDATE
        execute_commit_if.branch_instr           <= decode_execute_if.BRANCH_STRUCT.branch_instr;
        execute_commit_if.branch_taken           <= branch_if.branch_taken;
        execute_commit_if.prediction             <= decode_execute_if.BRANCH_STRUCT.prediction;
        execute_commit_if.br_resolved_addr       <= resolved_addr;
        execute_commit_if.pc4                    <= decode_execute_if.BRANCH_STRUCT.pc4;
        //Halt
        execute_commit_if.halt_instr             <= decode_execute_if.halt_instr;
        //CPU tracker
        execute_commit_if.CPU_TRACKER <= decode_execute_if.CPU_TRACKER;
       
      end
    end
  end

endmodule
