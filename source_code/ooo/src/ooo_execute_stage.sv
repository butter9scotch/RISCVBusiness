
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
  //jump_calc_if.execute jump_if,
  ooo_hazard_unit_if.execute hazard_if,
  //branch_res_if.execute branch_if,
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
  logic [1:0] byte_offset;
  //logic [3:0] byte_en_standard;
  word_t w_data, alu_port_b, alu_port_a;
  word_t updated_rs1_data, updated_rs2_data;
  word_t csr_wdata;
  logic intr_taken_ex;
  word_t branch_addr, resolved_addr;
  logic [4:0] reg_rd_mu_ff0, reg_rd_mu_ff1, reg_rd_mu_ff2;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_mu_ff0, index_mu_ff1, index_mu_ff2; 
  logic branch_mispredict;

  assign hazard_if.breakpoint  = decode_execute_if.exception_sigs.breakpoint;
  assign hazard_if.env_m       = decode_execute_if.exception_sigs.ecall_insn;
  assign hazard_if.pc_ex       = decode_execute_if.pc;
  
  /*******************************************************
  *** Arithmetic Unit
  *******************************************************/ 
  arithmetic_unit_if auif(.control_sigs(decode_execute_if.arith_sigs));
  // data signals
  assign auif.port_a          = decode_execute_if.port_a;
  assign auif.port_b          = decode_execute_if.port_b;
  assign auif.reg_file_wdata  = decode_execute_if.reg_file_wdata;
  assign auif.csr_rdata       = csr_rdata; // not sure how this will ever 
  assign auif.j_sel       = decode_execute_if.jump_sigs.j_sel; // not sure how this will ever 
  assign auif.pc       = decode_execute_if.pc; // not sure how this will ever 
  arithmetic_unit ARITHU (
    .auif(auif)
  );

  /*******************************************************
  *** Jumps
  *******************************************************/ 
  jump_calc_if jump_if(.control_sigs(decode_execute_if.jump_sigs));
  jump_calc jump_calc (.jump_if(jump_if));
  // extra signals used in execute stage
  logic jump_instr;
  assign jump_instr = decode_execute_if.jump_sigs.jump_instr;
  // outputs
  // assign execute_commit_if.jump_addr  = jump_if.jump_addr;


  /*******************************************************
  *** Branch Target Resolution and Associated Logic 
  *******************************************************/
  branch_res_if branch_if(.control_sigs(decode_execute_if.branch_sigs));
  // data inputs
  assign branch_if.rs1_data    = decode_execute_if.port_a;
  assign branch_if.rs2_data    = decode_execute_if.port_b;
  assign branch_if.pc          = decode_execute_if.pc;
  // TODO: fix this immediate needs to be passed to execute for sw and branches
  assign branch_if.imm_sb      = decode_execute_if.immediate;
  branch_res BRES (.br_if(branch_if));
  // extra signals used in execute stage
  assign branch_addr  = branch_if.branch_addr;
  assign resolved_addr = branch_if.branch_taken ? branch_addr : decode_execute_if.pc4;

  assign branch_mispredict = decode_execute_if.branch_sigs.branch_instr & (decode_execute_if.branch_sigs.prediction ^ branch_if.branch_taken);
  assign hazard_if.brj_addr = decode_execute_if.jump_sigs.jump_instr ? jump_if.jump_addr :
                              branch_mispredict ? branch_if.branch_addr : 
                              decode_execute_if.pc4;
  assign hazard_if.mispredict = decode_execute_if.jump_sigs.jump_instr || branch_mispredict;
  always_ff @(posedge CLK or negedge nRST) begin
    if (~nRST) begin 
      hazard_if.mispredict_ff <= '0; 
    end else begin
      hazard_if.mispredict_ff <= hazard_if.mispredict; 
    end
  end


  /*******************************************************
  *** Multiply Unit
  *******************************************************/ 
  multiply_unit_if  mif(.control_sigs(decode_execute_if.mult_sigs));
  always_ff @(posedge CLK or negedge nRST) begin
    if (~nRST) begin 
      reg_rd_mu_ff0 <= '0; 
      reg_rd_mu_ff1 <= '0; 
      reg_rd_mu_ff2 <= '0; 
      index_mu_ff0 <= '0;
      index_mu_ff1 <= '0;
      index_mu_ff2 <= '0;
    end else begin
      reg_rd_mu_ff0 <= mif.reg_rd_mu;
      reg_rd_mu_ff1 <= reg_rd_mu_ff0;
      reg_rd_mu_ff2 <= reg_rd_mu_ff1;
      index_mu_ff0 <= mif.index_mu;
      index_mu_ff1 <= index_mu_ff0;
      index_mu_ff2 <= index_mu_ff1;
    end
  end
  // data inputs
  assign mif.rs1_data = decode_execute_if.port_a;
  assign mif.rs2_data = decode_execute_if.port_b;
  multiply_unit MULU (.CLK(CLK), .nRST(nRST), .mif(mif));


  /*******************************************************
  *** Divide Unit
  *******************************************************/ 
  divide_unit_if    dif(.control_sigs(decode_execute_if.div_sigs));
  // data signals
  assign dif.rs1_data = decode_execute_if.port_a;
  assign dif.rs2_data = decode_execute_if.port_b;    
  divide_unit DIVU (.CLK(CLK), .nRST(nRST), .dif(dif));


  /*******************************************************
  *** Load Store Unit
  *******************************************************/ 
  loadstore_unit_if lsif(.control_sigs(decode_execute_if.lsu_sigs));
  // data lines
  assign lsif.port_a = decode_execute_if.port_a;
  assign lsif.port_b = decode_execute_if.port_b;
  assign lsif.store_data = decode_execute_if.store_data; // this is an issue here because sw needs three operands
  assign lsif.pc = decode_execute_if.pc;
  
  loadstore_unit LSU(
    .CLK(CLK),
    .nRST(nRST),
    .halt(halt), // halt should no longer be resolved here 
    .dgen_bus_if(dgen_bus_if),
    .hazard_if(hazard_if), 
    .lsif(lsif)
  );

  /*******************************************************
  *** Hazard Unit Signal Connections
  *******************************************************/
  //assign hazard_if.brj_addr   = ( jump_instr) ? jump_if.jump_addr : 
  //                                              branch_if.branch_addr;
  // assign hazard_if.mispredict = decode_execute_if.branch_sigs.prediction ^ branch_if.branch_taken;
  assign hazard_if.branch     = decode_execute_if.branch_sigs.branch_instr; 
  assign hazard_if.jump       = decode_execute_if.jump_sigs.jump_instr; 

  assign hazard_if.busy_au = auif.busy_au;
  assign hazard_if.busy_mu = mif.busy_mu;
  assign hazard_if.busy_du = dif.busy_du;
  //assign hazard_if.busy_ls = lsif.busy_ls;

  // assign hazard_if.load_stall = lsif.load_stall;

  /***** CSR STUFF? *****/
  //NEED CSR ENA SIGNAL
  assign csr_wdata = (decode_execute_if.csr_sigs.csr_imm) ? decode_execute_if.csr_sigs.csr_imm_value : decode_execute_if.csr_sigs.csr_wdata;

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
  assign hazard_if.csr     = csr_pulse;
  assign prv_pipe_if.swap  = decode_execute_if.csr_sigs.csr_swap;
  assign prv_pipe_if.clr   = decode_execute_if.csr_sigs.csr_clr;
  assign prv_pipe_if.set   = decode_execute_if.csr_sigs.csr_set;
  assign prv_pipe_if.wdata = csr_wdata;
  assign prv_pipe_if.addr  = decode_execute_if.csr_sigs.csr_addr;
  assign prv_pipe_if.valid_write = (prv_pipe_if.swap | prv_pipe_if.clr | prv_pipe_if.set); //TODO add to latch
  //assign prv_pipe_if.instr = (decode_execute_if.csr_sigs.csr_instr != '0);
  assign hazard_if.csr_pc = decode_execute_if.pc;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
      csr_reg <= 1'b0;
    else 
      csr_reg <= decode_execute_if.csr_sigs.csr_instr;
  end

  assign csr_pulse = decode_execute_if.csr_sigs.csr_instr && ~csr_reg;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
      csr_rdata <= 'h0;
    else if (csr_pulse)
      csr_rdata <= prv_pipe_if.rdata;
  end


  //Forwading logic
  assign hazard_if.load   = decode_execute_if.lsu_sigs.dren;

  always_ff @(posedge CLK, negedge nRST) begin : ARITH_UNIT
    if (~nRST) begin
      execute_commit_if.mult_sigs <= '0;
      execute_commit_if.div_sigs <= '0;
      execute_commit_if.lsu_sigs <= '0;
      execute_commit_if.arith_sigs <= '0;
    end else begin
      if (hazard_if.execute_commit_flush | (hazard_if.stall_ex & ~hazard_if.stall_commit) | halt) begin
        execute_commit_if.mult_sigs <= '0;
        execute_commit_if.div_sigs <= '0;
        execute_commit_if.lsu_sigs <= '0;
        execute_commit_if.arith_sigs <= '0;
      end else if(~hazard_if.stall_commit) begin
        execute_commit_if.mult_sigs <= decode_execute_if.mult_sigs;
        execute_commit_if.div_sigs <= decode_execute_if.div_sigs;
        execute_commit_if.lsu_sigs <= decode_execute_if.lsu_sigs;
        execute_commit_if.arith_sigs <= decode_execute_if.arith_sigs;
      end
    end
  end

  // word_t next_pc;
  // One pc port for the commit stage, more than one possible for the pc
  // to come from. we might be able to mux this, or it might need to be 
  // multiple signals. I think this will be important with exceptions,
  // right now we can just assign to brj pc
  // always_comb begin : NEXT_PC
  //   next_pc = auif.pc_a;
  // end

  /*******************************************************
  *** Execute Commit Latch
  *******************************************************/ 
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
      execute_commit_if.token            <= '0;
      execute_commit_if.intr_seen        <= '0;
      execute_commit_if.jump_instr       <= '0;
      execute_commit_if.jump_addr        <= '0;
      execute_commit_if.exception_a      <= 0; // TODO
      execute_commit_if.exception_mu     <= 0; // TODO
      execute_commit_if.exception_du     <= 0; // TODO
      execute_commit_if.exception_ls     <= 0; // TODO

      execute_commit_if.index_a  <= '0;
      execute_commit_if.index_mu <= '0;
      execute_commit_if.index_ls <= '0;
      execute_commit_if.index_du <= '0;

      //execute_commit_if.branch_instr     <= '0;
      execute_commit_if.br_resolved_addr <= '0;
      //BRANCH PREDICTOR UPDATE
      execute_commit_if.branch_instr      <= '0;
      execute_commit_if.branch_taken      <= '0;
      execute_commit_if.prediction        <= '0;
      execute_commit_if.br_resolved_addr  <= '0;
      execute_commit_if.pc                <= '0;
      execute_commit_if.pc_a                <= '0;
      execute_commit_if.pc4               <= '0;
      execute_commit_if.pc_ls    <= '0;

      //Halt
      execute_commit_if.halt_instr       <= '0;
      //CPU tracker
      execute_commit_if.CPU_TRACKER <= '0;
    end
    else begin
      if (hazard_if.execute_commit_flush | hazard_if.stall_commit & ~hazard_if.stall_ex || halt ) begin
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
        execute_commit_if.pc_a               <= '0;
        execute_commit_if.pc4               <= '0;
        execute_commit_if.token            <= '0;
        execute_commit_if.intr_seen        <= '0;
        execute_commit_if.jump_instr       <= '0;
        execute_commit_if.jump_addr        <= '0;
        execute_commit_if.exception_a            <= 0; // TODO
        execute_commit_if.exception_mu            <= 0; // TODO
        execute_commit_if.exception_du            <= 0; // TODO
        execute_commit_if.exception_ls            <= 0; // TODO

        execute_commit_if.index_a  <= '0;
        execute_commit_if.index_mu <= '0;
        execute_commit_if.index_ls <= '0;
        execute_commit_if.index_du <= '0;
        execute_commit_if.pc_ls    <= '0;


        //execute_commit_if.branch_instr     <= '0;
        execute_commit_if.br_resolved_addr <= '0;
        //BRANCH PREDICTOR UPDATE
        execute_commit_if.branch_instr      <= '0;
        execute_commit_if.branch_taken      <= '0;
        execute_commit_if.prediction        <= '0;
        execute_commit_if.br_resolved_addr  <= '0;
        execute_commit_if.pc_a                <= '0;
        execute_commit_if.pc                <= '0;
        execute_commit_if.pc4               <= '0;
        //Halt
        execute_commit_if.halt_instr       <= '0;
        //CPU tracker
        execute_commit_if.CPU_TRACKER <= '0;
      end else if (~hazard_if.stall_commit) begin
        execute_commit_if.done_ls <= lsif.done_ls;
        execute_commit_if.done_mu <= mif.done_mu;
        execute_commit_if.done_du <= dif.done_du;
        execute_commit_if.done_a  <= decode_execute_if.arith_sigs.ena; //auif.done_a;
        //WRITEBACK Signals:
        //ARITHMETIC
        execute_commit_if.wen_au                 <= auif.wen_au; 
        execute_commit_if.wdata_au               <= auif.wdata_au;
        execute_commit_if.reg_rd_au              <= auif.reg_rd_au;
        //MULTIPLY
        //execute_commit_if.wen_mu                 <= mif.done_mu; //done
        execute_commit_if.wdata_mu               <= mif.wdata_mu;
        execute_commit_if.reg_rd_mu              <= reg_rd_mu_ff2;
        execute_commit_if.index_mu               <= index_mu_ff2;
        //DIVIDE
        //execute_commit_if.wen_du                 <= dif.done_du; //or finished
        execute_commit_if.wdata_du               <= dif.wdata_du;
        if (dif.start_div) begin
                execute_commit_if.reg_rd_du              <= dif.reg_rd_du;
                execute_commit_if.index_du               <= dif.index_du;
        end
        //LOADSTORE
        execute_commit_if.wen_ls                 <= lsif.wen_ls; 
        execute_commit_if.wdata_ls               <= lsif.wdata_ls;
        execute_commit_if.reg_rd_ls              <= lsif.reg_rd_ls;
        execute_commit_if.opcode                 <= decode_execute_if.lsu_sigs.opcode;
        execute_commit_if.dren                   <= lsif.dren_ls;
        execute_commit_if.dwen                   <= lsif.dwen_ls;
        if (decode_execute_if.lsu_sigs.dren || decode_execute_if.lsu_sigs.dwen) begin
                execute_commit_if.pc_ls          <= decode_execute_if.pc;
        end
        //exception
        execute_commit_if.mal_addr               <= lsif.mal_addr;
        execute_commit_if.breakpoint             <= decode_execute_if.exception_sigs.breakpoint;
        execute_commit_if.ecall_insn             <= decode_execute_if.exception_sigs.ecall_insn;
        execute_commit_if.ret_insn               <= decode_execute_if.exception_sigs.ret_insn;
        execute_commit_if.illegal_insn           <= decode_execute_if.exception_sigs.illegal_insn;
        execute_commit_if.invalid_csr            <= prv_pipe_if.invalid_csr;
        execute_commit_if.mal_insn               <= decode_execute_if.exception_sigs.mal_insn;
        execute_commit_if.fault_insn             <= decode_execute_if.exception_sigs.fault_insn;
        execute_commit_if.memory_addr            <= lsif.memory_addr;
        execute_commit_if.pc_a                   <= decode_execute_if.pc;
        execute_commit_if.pc                     <= decode_execute_if.pc;
        execute_commit_if.token                  <= 0;
        execute_commit_if.intr_seen              <= intr_taken_ex; //TODO
        execute_commit_if.jump_instr             <= decode_execute_if.jump_sigs.jump_instr;
        execute_commit_if.jump_addr              <= jump_if.jump_addr;

        execute_commit_if.exception_a            <= 0; // TODO
        execute_commit_if.exception_mu           <= 0; // TODO
        execute_commit_if.exception_du           <= 0; // TODO
        //execute_commit_if.exception_ls           <= lsif.mal_addr; // TODO      
        if (execute_commit_if.exception_ls) execute_commit_if.exception_ls <= 0;
        else execute_commit_if.exception_ls      <= lsif.mal_addr;
        //execute_commit_if.branch_instr         <= branch_addr;
        execute_commit_if.br_resolved_addr       <= resolved_addr;
        //BRANCH PREDICTOR UPDATE
        execute_commit_if.branch_instr           <= decode_execute_if.branch_sigs.branch_instr;
        execute_commit_if.branch_taken           <= branch_if.branch_taken;
        execute_commit_if.prediction             <= decode_execute_if.branch_sigs.prediction;
        execute_commit_if.br_resolved_addr       <= resolved_addr;
        execute_commit_if.pc4                    <= decode_execute_if.pc4;

        execute_commit_if.index_a  <= auif.index_a;
        execute_commit_if.index_ls <= lsif.index_ls;

        
        //Halt
        execute_commit_if.halt_instr             <= decode_execute_if.halt_instr;
        //CPU tracker
        execute_commit_if.CPU_TRACKER <= decode_execute_if.tracker_sigs;
       
      end
    end
  end

endmodule
