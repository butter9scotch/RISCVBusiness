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
*   Filename:     ooo_decode_stage.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 02/24/2022
*   Description:  Decode stage for out of order pipeline 
*/

`include "ooo_fetch_decode_if.vh"
`include "ooo_decode_execute_if.vh"
`include "control_unit_if.vh"
`include "component_selection_defines.vh"
`include "rv32i_reg_file_if.vh"
`include "ooo_hazard_unit_if.vh"
`include "cache_control_if.vh"
`include "completion_buffer_if.vh"


module ooo_decode_stage (
  input logic CLK, nRST, halt,
  ooo_fetch_decode_if.decode fetch_decode_if,
  ooo_decode_execute_if.decode decode_execute_if,
  rv32i_reg_file_if.decode rf_if,
  ooo_hazard_unit_if.decode hazard_if,
  cache_control_if.pipeline cc_if,
  completion_buffer_if.decode cb_if
);

  import rv32i_types_pkg::*;
  import alu_types_pkg::*;
  //import rv32m_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  // Interface declarations
  control_unit_if   cu_if();
 
  // Module instantiations
  /*******************************************************
  * Input to the Control Unit
  *******************************************************/
  assign cu_if.instr = fetch_decode_if.instr;
  assign decode_execute_if.instr = fetch_decode_if.instr;
  assign cu_if.pc_en = hazard_if.pc_en;
  
  control_unit cu (
    .cu_if(cu_if)
  );
  
  /*******************************************************
  *** fence instruction and Associated Logic 
  *******************************************************/
  // posedge detector for ifence
  // subsequent ifences will have same effect as a single fence
  logic ifence_reg;
  logic ifence_pulse;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
      ifence_reg <= 1'b0;
    else if (hazard_if.pc_en)
      ifence_reg <= cu_if.ifence;
  end
  
  assign ifence_pulse = cu_if.ifence && ~ifence_reg;
  assign cc_if.icache_flush = ifence_pulse;
  assign cc_if.icache_clear = 1'b0;
  assign cc_if.dcache_flush = ifence_pulse;
  assign cc_if.dcache_clear = 1'b0;

  //regs to detect flush completion
  logic dflushed, iflushed;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
      iflushed <= 1'b1;
    else if (ifence_pulse)
      iflushed <= 1'b0;
    else if (cc_if.iflush_done & hazard_if.pc_en)
      iflushed <= 1'b1;
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
      dflushed <= 1'b1;
    else if (ifence_pulse)
      dflushed <= 1'b0;
    else if (cc_if.dflush_done & hazard_if.pc_en)
      dflushed <= 1'b1;
  end
  
  assign hazard_if.dflushed = dflushed;
  assign hazard_if.iflushed = iflushed;
  assign hazard_if.ifence = decode_execute_if.ifence;
  assign hazard_if.ifence_pc = decode_execute_if.pc;


  /*******************************************************
  * Reg File Logic
  *******************************************************/
  assign rf_if.rs1 = cu_if.reg_rs1;
  assign rf_if.rs2 = cu_if.reg_rs2;

  assign rf_if.rd_decode = cu_if.reg_rd;
  assign rf_if.rden = cu_if.wen & ~cu_if.branch;
  assign rf_if.clear_status = hazard_if.decode_execute_flush;
  
  /*******************************************************
  *** Sign Extensions of the Immediate Value
  *******************************************************/
  word_t imm_I_ext, imm_S_ext, imm_UJ_ext;

  // for jump calculation
  assign imm_I_ext  = {{20{cu_if.imm_I[11]}}, cu_if.imm_I};
  assign imm_UJ_ext = {{11{cu_if.imm_UJ[20]}}, cu_if.imm_UJ};

  // for source selection
  assign imm_S_ext  = {{20{cu_if.imm_S[11]}}, cu_if.imm_S};
  
  // word_t next_immediate;
  // always_comb begin
    
  // end 



  /*******************************************************
  *** Source Select Logic
  *******************************************************/
  word_t imm_or_shamt, next_reg_file_wdata;
  assign imm_or_shamt = (cu_if.imm_shamt_sel == 1'b1) ? cu_if.shamt : imm_I_ext;

  word_t fu_source_a;
  word_t fu_source_b;
  always_comb begin
    case (cu_if.source_a_sel)
      2'd0: fu_source_a = rf_if.rs1_data;
      2'd1: fu_source_a = imm_S_ext;
      2'd2: fu_source_a = fetch_decode_if.pc;
      2'd3: fu_source_a = '0; //Not Used 
    endcase
  end
 
  always_comb begin
    case(cu_if.source_b_sel)
      2'd0: fu_source_b = rf_if.rs1_data;
      2'd1: fu_source_b = rf_if.rs2_data;
      2'd2: fu_source_b = imm_or_shamt;
      2'd3: fu_source_b = cu_if.imm_U;
    endcase
  end

  always_comb begin
    case(cu_if.arith_sigs.w_src)
      3'd1    : next_reg_file_wdata = fetch_decode_if.pc4;
      3'd2    : next_reg_file_wdata = cu_if.imm_U;
      default : next_reg_file_wdata = '0; 
    endcase
  end
  
  /*******************************************************
  *** Jump Target Calculator and Associated Logic 
  *******************************************************/
  jump_control_signals_t jump_signals;
  word_t base, offset;

  always_comb begin
    if (cu_if.j_sel) begin
      base = fetch_decode_if.pc;
      offset = imm_UJ_ext;
    end else begin
      base = fu_source_a;
      offset = imm_I_ext;
    end
  end 
  assign jump_signals.j_base = base;
  assign jump_signals.j_offset = offset;
  assign jump_signals.jump_instr = cu_if.jump;
  assign jump_signals.j_sel = cu_if.j_sel;
 

  /*******************************************************
  *** Hazard unit connection  
  *******************************************************/
  assign hazard_if.halt = cu_if.halt; //TODO
  assign hazard_if.rs1_busy  = rf_if.rs1_busy;
  assign hazard_if.rs2_busy  = rf_if.rs2_busy;
  assign hazard_if.rd_busy   = rf_if.rd_busy;
  assign hazard_if.source_a_sel = cu_if.source_a_sel;
  assign hazard_if.source_b_sel = cu_if.source_b_sel;
  assign hazard_if.fu_type = decode_execute_if.sfu_type;
  always_comb begin
    case (cu_if.sfu_type) 
      LOADSTORE_S: hazard_if.wen = cu_if.lsu_sigs.wen;
      ARITH_S:     hazard_if.wen = cu_if.arith_sigs.wen;
      DIV_S:       hazard_if.wen = cu_if.div_sigs.wen;
      MUL_S:       hazard_if.wen = cu_if.mult_sigs.wen;
    endcase
  end



  /*********************************************************
  *** Signals for Bind Tracking - Read-Only, These don't affect execution
  *********************************************************/
  // CPU Tracker binding
  cpu_tracker_t CPU_TRACKER;
  assign CPU_TRACKER.funct3     = cu_if.instr[14:12];
  assign CPU_TRACKER.funct12    = cu_if.instr[31:20];
  assign CPU_TRACKER.instr_30   = cu_if.instr[30];
  assign CPU_TRACKER.imm_S      = cu_if.imm_S;
  assign CPU_TRACKER.imm_I      = cu_if.imm_I;
  assign CPU_TRACKER.imm_U      = cu_if.imm_U;
  assign CPU_TRACKER.imm_UJ_ext = imm_UJ_ext;
  assign CPU_TRACKER.imm_SB     = cu_if.imm_SB;
  assign CPU_TRACKER.reg_rs1    = cu_if.reg_rs1;
  assign CPU_TRACKER.reg_rs2    = cu_if.reg_rs2;
  assign CPU_TRACKER.instr      = fetch_decode_if.instr;
  assign CPU_TRACKER.reg_rd     = cu_if.reg_rd;
  assign CPU_TRACKER.pc         = fetch_decode_if.pc;
  assign CPU_TRACKER.opcode     = cu_if.opcode;

  /*********************************************************
  *** Stall signals
  *********************************************************/
  assign decode_execute_if.stall_multiply = hazard_if.stall_mu; 
  assign decode_execute_if.stall_divide = hazard_if.stall_du; 
  assign decode_execute_if.stall_arith = hazard_if.stall_au; 
  assign decode_execute_if.stall_loadstore = hazard_if.stall_ls; 

  /*********************************************************
  *** Completion buffer signals
  *********************************************************/
  logic TODO = 0;
  assign cb_if.alloc_ena =  ~hazard_if.stall_fetch_decode; 
  assign cb_if.rv32v_wb_scalar_ena  = TODO;
  assign cb_if.rv32v_instr  = TODO;
  assign cb_if.opcode = cu_if.opcode;

  always_ff @(posedge CLK, negedge nRST) begin : TOP_CONTROL_SIGNALS
    if (~nRST) begin
            //FUNC UNIT
            decode_execute_if.sfu_type   <= ARITH_S;
            //CPU tracker
            decode_execute_if.tracker_sigs <= '0;
    end 
    else begin 
        if ((hazard_if.decode_execute_flush |(hazard_if.stall_fetch_decode & ~hazard_if.stall_ex)) | halt) begin
            //FUNC UNIT
          decode_execute_if.sfu_type   <= ARITH_S;
            //CPU tracker
          decode_execute_if.tracker_sigs <= '0;
        end else if(~hazard_if.stall_ex) begin
          //FUNC UNIT
          decode_execute_if.sfu_type   <= cu_if.sfu_type;
          //CPU tracker
          decode_execute_if.tracker_sigs <= CPU_TRACKER;
        end
    end
  end

  /***** ALL BLOCKING INSTRUCTIONS GO HERE *****/
  logic is_blocking_instruction;
  assign is_blocking_instruction = cu_if.halt;
  assign hazard_if.busy_decode = is_blocking_instruction & (hazard_if.stall_au | hazard_if.stall_mu | hazard_if.stall_du | hazard_if.stall_ls);



  always_ff @(posedge CLK, negedge nRST) begin : BLOCKING_INSTRS
    if (~nRST) begin
            decode_execute_if.halt_instr <= '0;
    end 
    else begin 
        if ((hazard_if.decode_execute_flush |(hazard_if.stall_fetch_decode & ~hazard_if.stall_ex)) | hazard_if.stall_au | hazard_if.stall_mu | hazard_if.stall_du | hazard_if.stall_ls) begin
          decode_execute_if.halt_instr <= '0;
        end else if(~hazard_if.stall_ex & ~(hazard_if.stall_au | hazard_if.stall_mu | hazard_if.stall_du | hazard_if.stall_ls)) begin
          //HALT
          decode_execute_if.halt_instr <= cu_if.halt;
        end
    end
  end

  // BIG TODO: put in the logic for rs1 and rs2
  /***** OTHER FUNCTIONAL UNITS LATCH *****/
  always_ff @(posedge CLK, negedge nRST) begin : FUNCTIONAL_UNITS
    if (~nRST) begin
      decode_execute_if.mult_sigs <= '0;
      decode_execute_if.div_sigs <= '0;
      decode_execute_if.lsu_sigs <= '0;
    end else begin
      if (hazard_if.decode_execute_flush | (hazard_if.stall_fetch_decode & ~hazard_if.stall_ex) | halt) begin : FLUSH
        decode_execute_if.mult_sigs <= '0;
        decode_execute_if.div_sigs <= '0;
        //decode_execute_if.lsu_sigs <= '0;
//      end else if (~hazard_if.stall_de & hazard_if.pc_en) begin : BUBBLES
//          decode_execute_if.mult_sigs <= '0;
//          decode_execute_if.div_sigs <= '0;
//          decode_execute_if.lsu_sigs <= '0;
      end else begin
        //MULTIPLY
        if(~cu_if.mult_sigs.ena) begin
          decode_execute_if.mult_sigs <= '0;
        end else if(~(hazard_if.stall_mu)) begin
          decode_execute_if.mult_sigs.ena <= cu_if.mult_sigs.ena;
          decode_execute_if.mult_sigs.high_low_sel <= cu_if.mult_sigs.high_low_sel;
          decode_execute_if.mult_sigs.is_signed <= cu_if.mult_sigs.is_signed;
          decode_execute_if.mult_sigs.decode_done <= cu_if.mult_sigs.decode_done;
          decode_execute_if.mult_sigs.wen <= cu_if.mult_sigs.wen;
          decode_execute_if.mult_sigs.reg_rd <= cu_if.mult_sigs.reg_rd;
          decode_execute_if.mult_sigs.ready_mu <= cu_if.mult_sigs.ready_mu;
          decode_execute_if.mult_sigs.index_mu <= cb_if.cur_tail;
        end
       
        //DIVIDE
        if(~cu_if.div_sigs.ena) begin
          decode_execute_if.div_sigs <= '0;
        end else if(~(hazard_if.stall_du)) begin
          decode_execute_if.div_sigs.ena <= cu_if.div_sigs.ena;
          decode_execute_if.div_sigs.div_type <= cu_if.div_sigs.div_type;
          decode_execute_if.div_sigs.is_signed <= cu_if.div_sigs.is_signed;
          decode_execute_if.div_sigs.wen <= cu_if.div_sigs.wen;
          decode_execute_if.div_sigs.reg_rd <= cu_if.div_sigs.reg_rd;
          decode_execute_if.div_sigs.ready_du <= cu_if.div_sigs.ready_du;
          decode_execute_if.div_sigs.index_du <= cb_if.cur_tail;
        end

        // LOADSTORE
        if(~cu_if.lsu_sigs.ena) begin
          decode_execute_if.lsu_sigs <= '0;
        end else if(~(hazard_if.stall_ls)) begin
          decode_execute_if.lsu_sigs.load_type <= cu_if.lsu_sigs.load_type;
          //decode_execute_if.lsu_sigs.byte_en <= cu_if.lsu_sigs.byte_en;
          decode_execute_if.lsu_sigs.dren <= cu_if.lsu_sigs.dren;
          decode_execute_if.lsu_sigs.dwen <= cu_if.lsu_sigs.dwen;
          decode_execute_if.lsu_sigs.opcode <= cu_if.lsu_sigs.opcode;
          decode_execute_if.lsu_sigs.wen <= cu_if.lsu_sigs.wen;
          decode_execute_if.lsu_sigs.reg_rd <= cu_if.lsu_sigs.reg_rd;
          decode_execute_if.lsu_sigs.ready_ls <= cu_if.lsu_sigs.ready_ls;
          decode_execute_if.lsu_sigs.index_ls <= cb_if.cur_tail;
          decode_execute_if.store_data <= rf_if.rs2_data;
        end

      end
    end
  end

  /***** FUNCTIONAL UNIT SOURCE LATCHES *****/
  always_ff @(posedge CLK, negedge nRST) begin : SOURCE_LATCHES
    if(~nRST) begin
      decode_execute_if.pc <= '0;
      decode_execute_if.pc4 <= '0;
      decode_execute_if.immediate <= '0;
      decode_execute_if.port_a <= '0; 
      decode_execute_if.port_b <= '0; 
      decode_execute_if.lsu_sigs.opcode <= '0;    
    end else begin 
      if(hazard_if.decode_execute_flush | (hazard_if.stall_fetch_decode & ~hazard_if.stall_ex) | halt) begin
        decode_execute_if.pc <= '0;
        decode_execute_if.pc4 <= '0;
        decode_execute_if.immediate <= '0;
        decode_execute_if.port_a <= '0; 
        decode_execute_if.port_b <= '0; 
        decode_execute_if.lsu_sigs.opcode <= '0;
      end else if(~hazard_if.stall_ex) begin
        decode_execute_if.pc <= fetch_decode_if.pc;
        decode_execute_if.pc4 <= fetch_decode_if.pc4;
        decode_execute_if.immediate <= cu_if.imm_SB; // TODO figure out how to do this
        decode_execute_if.port_a <= fu_source_a; 
        decode_execute_if.port_b <= fu_source_b; 
        decode_execute_if.lsu_sigs.opcode <= cu_if.opcode;
      end
    end
  end

  /***** ARITHMETIC UNIT/CSR/EXCEPTION LATCH *****/
  always_ff @(posedge CLK, negedge nRST) begin : ARITH_UNIT
    if (~nRST) begin
      decode_execute_if.arith_sigs <= '0;
      decode_execute_if.reg_file_wdata <= '0;
      //JUMP
      decode_execute_if.jump_sigs        <= '0;
      //BRANCH
      decode_execute_if.branch_sigs <= '0;
      //csr
      decode_execute_if.csr_sigs <= '0;
      //Exceptions
      decode_execute_if.exception_sigs <= '0;
        
    end else begin
      if (hazard_if.decode_execute_flush | (~hazard_if.stall_au & hazard_if.stall_fetch_decode) | halt) begin
        decode_execute_if.arith_sigs <= '0;
        decode_execute_if.reg_file_wdata <= '0;
        //JUMP
        decode_execute_if.jump_sigs <= '0;
        //BRANCH
        decode_execute_if.branch_sigs <= '0;
        //csr
        decode_execute_if.csr_sigs <= '0;
        //Exceptions
        decode_execute_if.exception_sigs <= '0;

      end else if(~cu_if.arith_sigs.ena) begin
        decode_execute_if.arith_sigs <= '0;
        decode_execute_if.reg_file_wdata <= next_reg_file_wdata;
        decode_execute_if.jump_sigs <= '0;
        decode_execute_if.branch_sigs <= 0;
        decode_execute_if.csr_sigs <= '0;

        //Exceptions
        // elaborateed because half of the signals are form cu_if and 
        // other half is from the fetch decode latch
        decode_execute_if.exception_sigs.illegal_insn <= cu_if.illegal_insn;
        decode_execute_if.exception_sigs.breakpoint   <= cu_if.breakpoint;
        decode_execute_if.exception_sigs.ecall_insn   <= cu_if.ecall_insn;
        decode_execute_if.exception_sigs.ret_insn     <= cu_if.ret_insn;
        decode_execute_if.exception_sigs.token        <= fetch_decode_if.token;
        decode_execute_if.exception_sigs.mal_insn     <= fetch_decode_if.mal_insn;
        decode_execute_if.exception_sigs.fault_insn   <= fetch_decode_if.fault_insn;
        decode_execute_if.exception_sigs.wfi          <= cu_if.wfi;
        decode_execute_if.exception_sigs.w_src        <= cu_if.arith_sigs.w_src;
      end else if(~hazard_if.stall_au) begin
        decode_execute_if.arith_sigs.ena <= cu_if.arith_sigs.ena;
        decode_execute_if.arith_sigs.alu_op <= cu_if.arith_sigs.alu_op;
        decode_execute_if.arith_sigs.w_src <= cu_if.arith_sigs.w_src;
        decode_execute_if.arith_sigs.wen <= cu_if.arith_sigs.wen;
        decode_execute_if.arith_sigs.reg_rd <= cu_if.arith_sigs.reg_rd;
        decode_execute_if.arith_sigs.ready_a <= cu_if.arith_sigs.ready_a;
        decode_execute_if.arith_sigs.index_a <= cb_if.cur_tail;

        decode_execute_if.reg_file_wdata <= next_reg_file_wdata;
        //JUMP
        decode_execute_if.jump_sigs <= jump_signals;
        //BRANCH
        // pretty sure this line is unecessary
        // decode_execute_if.branch_sigs.br_imm_sb       <= cu_if.imm_SB;
        decode_execute_if.branch_sigs.branch_type  <= cu_if.branch_type;
        decode_execute_if.branch_sigs.branch_instr      <= cu_if.branch;
        //BRANCH PREDICTOR UPDATE
        decode_execute_if.branch_sigs.prediction <= fetch_decode_if.prediction;
        //CSR
        decode_execute_if.csr_sigs <= cu_if.csr_sigs;

        //Exceptions
        // elaborateed because half of the signals are form cu_if and 
        // other half is from the fetch decode latch
        decode_execute_if.exception_sigs.illegal_insn <= cu_if.illegal_insn;
        decode_execute_if.exception_sigs.breakpoint   <= cu_if.breakpoint;
        decode_execute_if.exception_sigs.ecall_insn   <= cu_if.ecall_insn;
        decode_execute_if.exception_sigs.ret_insn     <= cu_if.ret_insn;
        decode_execute_if.exception_sigs.token        <= fetch_decode_if.token;
        decode_execute_if.exception_sigs.mal_insn     <= fetch_decode_if.mal_insn;
        decode_execute_if.exception_sigs.fault_insn   <= fetch_decode_if.fault_insn;
        decode_execute_if.exception_sigs.wfi          <= cu_if.wfi;
        decode_execute_if.exception_sigs.w_src        <= cu_if.arith_sigs.w_src;

      end
    end
  end

endmodule
