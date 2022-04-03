
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
`include "scalar_vector_decode_if.vh"  
`include "cache_model_if.vh" 
`include "rv32v_hazard_unit_if.vh"
`include "rv32v_top_level_if.vh"
`include "ooo_bypass_unit_if.vh"
`include "completion_buffer_if.vh"

module ooo_execute_stage(
  input logic CLK, nRST,halt,
  ooo_decode_execute_if.execute decode_execute_if,
  ooo_execute_commit_if.execute execute_commit_if,
  //jump_calc_if.execute jump_if,
  ooo_hazard_unit_if.execute hazard_if,
  //branch_res_if.execute branch_if,
  cache_control_if.pipeline cc_if,
  prv_pipeline_if.pipe  prv_pipe_if,
  generic_bus_if.cpu dgen_bus_if,
  ooo_bypass_unit_if.execute bypass_if,
  completion_buffer_if.execute cb_if,
  rv32v_reorder_buffer_if rob_if
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
  assign hazard_if.ret         = decode_execute_if.exception_sigs.ret_insn;
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
  generic_bus_if scalar_gen_bus_if();
  loadstore_unit LSU(
    .CLK(CLK),
    .nRST(nRST),
    .halt(halt), // halt should no longer be resolved here 
    .dgen_bus_if(scalar_gen_bus_if),
    .hazard_if(hazard_if), 
    .lsif(lsif)
  );

  /*******************************************************
  *** Vector Unit
  *******************************************************/ 
  //scalar_vector_decode_if  rv32v_decode_if();
  rv32v_hazard_unit_if rv32v_hazard_if();
  cache_model_if cif();
  rv32v_top_level_if rv32v_if();

  logic v_start_pulse, v_start_reg;

  assign v_start_pulse = decode_execute_if.v_sigs.ena & ~v_start_reg; 

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
      v_start_reg <= 0;
    end else begin
      v_start_reg <= decode_execute_if.v_sigs.ena;
    end 
  end

  assign rv32v_hazard_if.csr_update = 0;
  assign hazard_if.v_busy = rv32v_hazard_if.v_busy;
  
  // Assign signals to top-level vector unit interface
  assign rv32v_if.instr = decode_execute_if.v_sigs.sfu_type == VECTOR_S ? decode_execute_if.instr : '0;
  assign rv32v_if.rs1_data        = decode_execute_if.v_sigs.rs1_data;
  assign rv32v_if.rs2_data        = decode_execute_if.v_sigs.rs2_data;
  assign rv32v_if.alloc_ena       = decode_execute_if.valloc_ena;
  assign rv32v_if.index           = decode_execute_if.v_sigs.rob_index_v;
  assign rv32v_if.v_single_bit_op = decode_execute_if.v_single_bit_op;
  assign rv32v_if.v_commit_ena    = cb_if.v_commit_ena;
  assign rv32v_if.v_start    = v_start_pulse;

  assign cb_if.v_commit_done     = rv32v_if.v_commit_done; 
  //TODO: this should go through the top level interface
  //but maybe it is deprecated 
  assign decode_execute_if.rob_index = rv32v_if.rob_index;
  
  generic_bus_if vector_gen_bus_if();
  // translation of the vector cache model if to the generic bus if
  // used by the arbitor and system level
  assign vector_gen_bus_if.addr    = cif.dmemaddr;
  assign vector_gen_bus_if.ren     = cif.ren;
  assign vector_gen_bus_if.wen     = cif.wen;
  assign vector_gen_bus_if.wdata   = cif.dmemstore;
  assign vector_gen_bus_if.byte_en = cif.byte_ena;
  assign cif.dmemload              = vector_gen_bus_if.rdata;
  assign cif.dhit                  = ~vector_gen_bus_if.busy;

  rv32v_top_level RVV (
    .CLK,
    .nRST,
    .cif(cif),
    .hu_if(rv32v_hazard_if),
    .prv_if(prv_pipe_if),
    .rv32v_if,
    .rob_if
  );

  
  /*******************************************************
  *** Data Memory Arbitration
  *******************************************************/ 
  rv32v_memory_arbitor_if arb_if();
  memory_arbitor mem_arb(
    .arb_if(arb_if),
    .scalar_gen_bus_if(scalar_gen_bus_if),
    .vector_gen_bus_if(vector_gen_bus_if),
    .out_gen_bus_if(dgen_bus_if)
  );
  assign arb_if.cb_tail_index   = cb_if.cur_tail;
  assign arb_if.vector_cb_index = decode_execute_if.v_sigs.index_v;
  assign arb_if.scalar_cb_index = lsif.index_ls;
  /*******************************************************
  *** Hazard Unit Signal Connections
  /t*******************************************************/
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
  assign csr_wdata = decode_execute_if.csr_sigs.csr_wdata;

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
  assign prv_pipe_if.vector_csr_instr = decode_execute_if.csr_sigs.vector_csr_instr;
  //assign prv_pipe_if.instr = (decode_execute_if.csr_sigs.csr_instr != '0);
  assign hazard_if.csr_pc = decode_execute_if.pc;

  logic csr_pulse_reg;
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      csr_reg <= 1'b0;
      csr_pulse_reg <= 1'b0;
    end else begin
      csr_reg <= decode_execute_if.csr_sigs.csr_instr;
      csr_pulse_reg <= csr_pulse;
    end
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

  /*******************************************************
  *** Execute-commit latch for functional unit signals
  *******************************************************/
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
      execute_commit_if.exception_a      <= '0; 
      execute_commit_if.exception_mu     <= '0; 
      execute_commit_if.exception_du     <= '0; 
      execute_commit_if.exception_ls     <= '0; 

      execute_commit_if.index_a          <= '0;
      execute_commit_if.index_mu         <= '0;
      execute_commit_if.index_ls         <= '0;
      execute_commit_if.index_du         <= '0;

      //execute_commit_if.branch_instr    <= '0;
      execute_commit_if.br_resolved_addr  <= '0;
      //BRANCH PREDICTOR UPDATE
      execute_commit_if.branch_instr      <= '0;
      execute_commit_if.branch_taken      <= '0;
      execute_commit_if.prediction        <= '0;
      execute_commit_if.br_resolved_addr  <= '0;
      execute_commit_if.pc                <= '0;
      execute_commit_if.pc_a              <= '0;
      execute_commit_if.pc4               <= '0;
      execute_commit_if.pc_ls             <= '0;

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
        execute_commit_if.pc_a             <= '0;
        execute_commit_if.pc4              <= '0;
        execute_commit_if.token            <= '0;
        execute_commit_if.intr_seen        <= '0;
        execute_commit_if.jump_instr       <= '0;
        execute_commit_if.jump_addr        <= '0;
        execute_commit_if.exception_a      <= '0;  
        execute_commit_if.exception_mu     <= '0; 
        execute_commit_if.exception_du     <= '0; 
        execute_commit_if.exception_ls     <= '0; 

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
        execute_commit_if.wdata_au               <= decode_execute_if.csr_sigs.csr_swap ? csr_rdata : auif.wdata_au;
        execute_commit_if.reg_rd_au              <= auif.reg_rd_au;
        //MULTIPLY
        //execute_commit_if.wen_mu                 <= mif.done_mu; //done
        execute_commit_if.wdata_mu               <= mif.wdata_mu;
        execute_commit_if.reg_rd_mu              <= reg_rd_mu_ff2;
        execute_commit_if.index_mu               <= index_mu_ff2;
        //DIVIDE
        //execute_commit_if.wen_du                 <= dif.done_du; //or finished
        execute_commit_if.wdata_du               <= dif.wdata_du;
        /*if (dif.start_div) begin
                execute_commit_if.reg_rd_du              <= dif.reg_rd_du;
                execute_commit_if.index_du               <= dif.index_du;
        end */
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

       // Forgot to put these in the latch??? 
        execute_commit_if.index_v                <= decode_execute_if.v_sigs.index_v;
        execute_commit_if.reg_rd_v               <= rv32v_if.rd_sel;
        execute_commit_if.done_v                 <= rv32v_if.done;       
        execute_commit_if.done_v                 <= ~hazard_if.v_busy & decode_execute_if.v_sigs.ena;       
        execute_commit_if.exception_v            <= rv32v_if.exception_v;
        execute_commit_if.wdata_v                <= rv32v_if.rd_data;     
        execute_commit_if.wen_v                  <= rv32v_if.rd_wen;     
          
        //Halt
        execute_commit_if.halt_instr             <= decode_execute_if.halt_instr;
        //CPU tracker
        execute_commit_if.CPU_TRACKER <= decode_execute_if.tracker_sigs;
       
      end
    end
  end

  // -------------------------------------------------------------------------NEW OPT-------------------------------------
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_a;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_mu;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_du;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_ls;
  word_t wdata_a;
  word_t wdata_mu;
  word_t wdata_du;
  word_t wdata_ls;
  logic [4:0] vd_a;
  logic [4:0] vd_mu;
  logic [4:0] vd_du;
  logic [4:0] vd_ls;
  logic exception_a;
  logic exception_mu;
  logic exception_du;
  logic exception_ls;
  logic ready_a;
  logic ready_mu;
  logic ready_du;
  logic ready_ls;
  logic wen_a;
  logic wen_ls;
  logic mal_ls;
  logic valid_pc;
  logic mal_pulse;
  logic mal_reg;
  logic [4:0] reg_rd_du_reg;
  logic [4:0] index_du_reg;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      reg_rd_du_reg <= '0;
      index_du_reg <= '0;
    end else if (dif.start_div) begin
      reg_rd_du_reg <= dif.reg_rd_du;
      index_du_reg <= dif.index_du;
    end
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
      mal_reg <= 1'b0;
    else 
      mal_reg <= lsif.mal_addr;
  end

  assign mal_pulse = lsif.mal_addr & ~mal_reg;
  assign valid_pc  = decode_execute_if.lsu_sigs.opcode != opcode_t'('h0);

  assign index_a   = auif.index_a;
  assign index_mu  = index_mu_ff2;
  assign index_du  = (dif.start_div & dif.done_du) ? dif.index_du : index_du_reg;
  assign index_ls  = lsif.index_ls;

  assign vd_a  = auif.reg_rd_au;
  assign vd_mu = reg_rd_mu_ff2;
  assign vd_du = (dif.start_div & dif.done_du) ? dif.reg_rd_du : reg_rd_du_reg;
  assign vd_ls = lsif.reg_rd_ls;

  assign exception_a  = 0;
  assign exception_mu = 0;
  assign exception_du = 0;
  assign exception_ls = mal_pulse; 

  assign ready_a  = decode_execute_if.csr_sigs.csr_instr ? csr_pulse_reg : (auif.wen_au | decode_execute_if.branch_sigs.branch_instr | decode_execute_if.jump_sigs.jump_instr & valid_pc) & decode_execute_if.arith_sigs.ena; 
  assign ready_mu = mif.done_mu;
  assign ready_du = dif.done_du;
  assign ready_ls = lsif.done_ls | exception_ls;

  assign wdata_a   = decode_execute_if.jump_sigs.jump_instr ? decode_execute_if.pc + 4 : decode_execute_if.csr_sigs.csr_swap ? csr_rdata : auif.wdata_au;
  assign wdata_mu  = mif.wdata_mu;  
  assign wdata_du  = dif.wdata_du;
  assign wdata_ls  = exception_ls ? execute_commit_if.pc_ls : lsif.wdata_ls; 

  assign wen_a  = (exception_a | decode_execute_if.branch_sigs.branch_instr) ? 1'b0 : 1'b1;
  assign wen_ls = lsif.wen_ls & ~exception_ls; 

  assign mal_ls = mal_pulse; 

  assign bypass_if.rd_alu    = vd_a;
  assign bypass_if.valid_alu = wen_a & ready_a;
  assign bypass_if.data_alu  = wdata_a;
  assign bypass_if.rd_mul    = vd_mu;
  assign bypass_if.valid_mul = ready_mu;
  assign bypass_if.data_mul  = wdata_mu;
  assign bypass_if.rd_div    = vd_du;
  assign bypass_if.valid_div = ready_du;
  assign bypass_if.data_div  = wdata_du;
  assign bypass_if.rd_lsu    = vd_ls;
  assign bypass_if.valid_lsu = wen_ls & ready_ls & ~exception_ls;
  assign bypass_if.data_lsu  = wdata_ls;

  assign cb_if.index_a     = index_a; 
  assign cb_if.wdata_a     = wdata_a; 
  assign cb_if.vd_a        = vd_a; 
  assign cb_if.exception_a = exception_a; 
  assign cb_if.ready_a     = ready_a; 
  assign cb_if.wen_a       = wen_a; 

  assign cb_if.index_mu     = index_mu; 
  assign cb_if.wdata_mu     = wdata_mu;  
  assign cb_if.vd_mu        = vd_mu; 
  assign cb_if.exception_mu = exception_mu; 
  assign cb_if.ready_mu     = ready_mu; 

  assign cb_if.index_du     = index_du; 
  assign cb_if.wdata_du     = wdata_du; 
  assign cb_if.vd_du        = vd_du; 
  assign cb_if.exception_du = exception_du; 
  assign cb_if.ready_du     = ready_du; 

  assign cb_if.index_ls     = index_ls; 
  assign cb_if.wdata_ls     = wdata_ls; 
  assign cb_if.vd_ls        = vd_ls; 
  assign cb_if.exception_ls = exception_ls; 
  assign cb_if.ready_ls     = ready_ls; 
  assign cb_if.mal_ls       = mal_ls; 
  assign cb_if.wen_ls       = wen_ls; 

//  assign cb_if.index_v     = index_v; 
  assign cb_if.wdata_v     = rv32v_if.rd_data; 
  assign cb_if.vd_v        = rv32v_if.rd_sel; 
//  assign cb_if.exception_v = exception_v; 
  assign cb_if.ready_v     = rv32v_if.done; 
  assign cb_if.index_v     = decode_execute_if.v_sigs.index_v; 
//  assign cb_if.mal_v       = mal_v; 
  assign cb_if.wen_v       = rv32v_if.rd_wen; 

  assign cb_if.halt_instr   = decode_execute_if.halt_instr;

endmodule