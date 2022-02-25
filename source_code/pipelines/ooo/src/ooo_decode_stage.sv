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

`include "ooo_fetch2_decode_if.vh"
`include "ooo_decode_execute_if.vh"
`include "control_unit_if.vh"
`include "component_selection_defines.vh"
`include "rv32i_reg_file_if.vh"
`include "ooo_hazard_unit_if.vh"
`include "cache_control_if.vh"


module ooo_decode_stage (
  input logic CLK, nRST, halt,
  ooo_fetch2_decode_if.decode fetch_decode_if,
  ooo_decode_execute_if.decode decode_execute_if,
  rv32i_reg_file_if.decode rf_if,
  ooo_hazard_unit_if.decode hazard_if,
  cc_if
);

  import rv32i_types_pkg::*;
  import alu_types_pkg::*;
  //import rv32m_pkg::*;
  import machine_mode_types_1_11_pkg::*;
  logic [2:0] funct3;
  logic [11:0] funct12;

  // Interface declarations
  control_unit_if   cu_if();
 
  // Module instantiations
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
  * FU signals
  *******************************************************/

  logic mul_ena, div_ena, arith_ena, loadstore_ena;
  assign mul_ena       = cu_if.sfu_type == MUL_S;
  assign div_ena       = cu_if.sfu_type == DIV_S;
  assign arith_ena = cu_if.sfu_type == ARITH_S;
  assign loadstore_ena = cu_if.sfu_type == LOADSTORE_S;


  /*******************************************************
  * Reg File Logic
  *******************************************************/
   assign rf_if.rs1 = cu_if.reg_rs1;
   assign rf_if.rs2 = cu_if.reg_rs2;

  /*******************************************************
  * MISC RISC-MGMT Logic
  *******************************************************/
  assign cu_if.instr = fetch_decode_if.instr;

  /*******************************************************
  *** Sign Extensions 
  *******************************************************/
  word_t imm_I_ext, imm_S_ext, imm_UJ_ext;
  assign imm_I_ext  = {{20{cu_if.imm_I[11]}}, cu_if.imm_I};
  assign imm_UJ_ext = {{11{cu_if.imm_UJ[20]}}, cu_if.imm_UJ};
  assign imm_S_ext  = {{20{cu_if.imm_S[11]}}, cu_if.imm_S};

  /*******************************************************
  *** Jump Target Calculator and Associated Logic 
  *******************************************************/
  word_t base, offset;
  always_comb begin
    if (cu_if.j_sel) begin
      base = fetch_decode_if.pc;
      offset = imm_UJ_ext;
    end else begin
      base = rf_if.rs1_data;
      offset = imm_I_ext;
    end
  end 

  /*******************************************************
  *** ALU and Associated Logic 
  *******************************************************/
  word_t imm_or_shamt, next_port_a, next_port_b, next_reg_file_wdata;
  assign imm_or_shamt = (cu_if.imm_shamt_sel == 1'b1) ? cu_if.shamt : imm_I_ext;
 
  always_comb begin
    case (cu_if.alu_a_sel)
      2'd0: next_port_a = rf_if.rs1_data;
      2'd1: next_port_a = imm_S_ext;
      2'd2: next_port_a = fetch_decode_if.pc;
      2'd3: next_port_a = '0; //Not Used 
    endcase
  end
 
  always_comb begin
    case(cu_if.alu_b_sel)
      2'd0: next_port_b = rf_if.rs1_data;
      2'd1: next_port_b = rf_if.rs2_data;
      2'd2: next_port_b = imm_or_shamt;
      2'd3: next_port_b = cu_if.imm_U;
    endcase
  end

  always_comb begin
    case(cu_if.w_src)
      3'd1    : next_reg_file_wdata = fetch_decode_if.pc4;
      3'd2    : next_reg_file_wdata = cu_if.imm_U;
      default : next_reg_file_wdata = '0; 
    endcase
  end
  
  /*******************************************************
  *** Hazard unit connection  
  *******************************************************/

  assign hazard_if.halt = cu_if.halt;

  /*********************************************************
  *** Signals for Bind Tracking - Read-Only, These don't affect execution
  *********************************************************/
  assign funct3 = cu_if.instr[14:12];
  assign funct12 = cu_if.instr[31:20];
  assign instr_30 = cu_if.instr[30];
  /*********************************************************
  *** Stall signals
  *********************************************************/
  assign stall_multiply = hazard_if.stall; 
  assign stall_divide = hazard_if.stall; 
  assign stall_arith = hazard_if.stall; 
  assign stall_loadstore = hazard_if.stall; 



  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
            //FUNC UNIT
            decode_execute_if.sfu_type <= ARITH_S;
           //REG_FILE/ WRITEBACK
            //HALT
            decode_execute_if.halt_instr                <= '0;
            //CPU tracker
            decode_execute_if.funct3                    <= '0;
            decode_execute_if.funct12                   <= '0;
            decode_execute_if.imm_S                     <= '0;
            decode_execute_if.imm_I                     <= '0;
            decode_execute_if.imm_U                     <= '0;
            decode_execute_if.imm_UJ_ext                <= '0;
            decode_execute_if.imm_SB                    <= '0;
            decode_execute_if.instr_30                  <= '0;
    end 
    else begin 
        if (((hazard_if.id_ex_flush | hazard_if.stall) & hazard_if.pc_en) | halt) begin
            //FUNC UNIT
          decode_execute_if.sfu_type <= ARITH_S;
           //REG_FILE/ WRITEBACK
            //HALT
          decode_execute_if.halt_instr                <= '0;
            //CPU tracker
          decode_execute_if.funct3                    <= '0;
          decode_execute_if.funct12                   <= '0;
          decode_execute_if.imm_S                     <= '0;
          decode_execute_if.imm_I                     <= '0;
          decode_execute_if.imm_U                     <= '0;
          decode_execute_if.imm_UJ_ext                <= '0;
          decode_execute_if.imm_SB                    <= '0;
          decode_execute_if.instr_30                  <= '0;
        end else if(hazard_if.pc_en & ~hazard_if.stall) begin
          //FUNC UNIT
          decode_execute_if.sfu_type <= cu_if.sfu_type;
          //REG_FILE/ WRITEBACK
          //HALT
          decode_execute_if.halt_instr                <= cu_if.halt;
          //CPU tracker
          decode_execute_if.funct3                    <= funct3;
          decode_execute_if.funct12                   <= funct12;
          decode_execute_if.imm_S                     <= cu_if.imm_S;
          decode_execute_if.imm_I                     <= cu_if.imm_I;
          decode_execute_if.imm_U                     <= cu_if.imm_U;
          decode_execute_if.imm_UJ_ext                <= imm_UJ_ext;
          decode_execute_if.imm_SB                    <= cu_if.imm_SB;
          decode_execute_if.instr_30                  <= instr_30;
        end
    end
  end

  always @(posedge CLK, negedge nRST) begin : MULTIPLY_UNIT
    if (~nRST) begin
      decode_execute_if.multiply.rs1_data <= 0;
      decode_execute_if.multiply.rs2_data <= 0;
      decode_execute_if.multiply.start_mu <= 0;
      decode_execute_if.multiply.high_low_sel <= 0;
      decode_execute_if.multiply.decode_done <= 0;
      decode_execute_if.multiply.wen <= 0;
      decode_execute_if.multiply.is_signed <= SIGNED;
      decode_execute_if.multiply.reg_rd <= 0;
    end else begin
      if (((hazard_if.id_ex_flush | hazard_if.stall_mu) & hazard_if.pc_en) | halt) begin
        decode_execute_if.multiply.rs1_data <= 0;
        decode_execute_if.multiply.rs2_data <= 0;
        decode_execute_if.multiply.start_mu <= 0;
        decode_execute_if.multiply.high_low_sel <= 0;
        decode_execute_if.multiply.decode_done <= 0;
        decode_execute_if.multiply.wen <= 0;
        decode_execute_if.multiply.is_signed <= SIGNED;
        decode_execute_if.multiply.reg_rd <= 0;
      end else if(hazard_if.pc_en & ~hazard_if.stall_mu) begin
        decode_execute_if.multiply.rs1_data       <= rf_if.rs1_data;
        decode_execute_if.multiply.rs2_data       <= rf_if.rs2_data;
        decode_execute_if.multiply.start_mu       <= mul_ena;
        decode_execute_if.multiply.high_low_sel   <= cu_if.high_low_sel;
        decode_execute_if.multiply.decode_done    <= 0;
        decode_execute_if.multiply.wen            <= cu_if.wen;
        decode_execute_if.multiply.is_signed      <= cu_if.sign_type;
        decode_execute_if.multiply.reg_rd         <= cu_if.reg_rd;
      end
    end
  end

  always @(posedge CLK, negedge nRST) begin : DIVIDE_UNIT
    if (~nRST) begin
      decode_execute_if.divide.rs1_data <= 0;
      decode_execute_if.divide.rs2_data <= 0;
      decode_execute_if.divide.start_div <= 0;
      decode_execute_if.divide.div_type <= 0;
      decode_execute_if.divide.is_signed_div <= 0;
      decode_execute_if.divide.wen <= 0;
      decode_execute_if.divide.reg_rd <= 0;
    end else begin 
      if (((hazard_if.id_ex_flush | hazard_if.stall_du) & hazard_if.pc_en) | halt) begin
        decode_execute_if.divide.rs1_data <= 0;
        decode_execute_if.divide.rs2_data <= 0;
        decode_execute_if.divide.start_div <= 0;
        decode_execute_if.divide.div_type <= 0;
        decode_execute_if.divide.is_signed_div <= 0;
        decode_execute_if.divide.wen <= 0;
        decode_execute_if.divide.reg_rd <= 0;
      end else if(hazard_if.pc_en & ~hazard_if.stall_du) begin
        decode_execute_if.divide.rs1_data <= rf_if.rs1_data;
        decode_execute_if.divide.rs2_data <= rf_if.rs2_data;
        decode_execute_if.divide.start_div <= div_ena;
        decode_execute_if.divide.div_type <= cu_if.div_type;
        decode_execute_if.divide.is_signed_div <= cu_if.sign_type;
        decode_execute_if.divide.wen <= cu_if.wen;
        decode_execute_if.divide.reg_rd <= cu_if.reg_rd;
      end
    end
  end

  always @(posedge CLK, negedge nRST) begin : ARITH_UNIT
    if (~nRST) begin
        decode_execute_if.arith.aluop <= 0;
        decode_execute_if.arith.port_a <= 0;
        decode_execute_if.arith.port_b <= 0;
        //JUMP
        decode_execute_if.arith.jump_instr                <= '0;
        decode_execute_if.arith.j_base                    <= '0;
        decode_execute_if.arith.j_offset                  <= '0;
        decode_execute_if.arith.j_sel                     <= '0;
        //BRANCH
        decode_execute_if.arith.br_imm_sb                 <= '0;
        decode_execute_if.arith.br_branch_type            <= '0;
        //BRANCH PREDICTOR UPDATE
        decode_execute_if.arith.branch_instr              <= '0;
        decode_execute_if.arith.prediction                <= '0;
        decode_execute_if.arith.pc                        <= '0;
        decode_execute_if.arith.pc4                       <= '0;
        //csr
        decode_execute_if.CSR_STRUCT.csr_instr                 <= '0;
        decode_execute_if.arith.csr_swap                  <= '0;
        decode_execute_if.arith.csr_clr                   <= '0;
        decode_execute_if.arith.csr_set                   <= '0;
        decode_execute_if.arith.csr_addr                  <= '0;
        decode_execute_if.arith.csr_imm                   <= '0;
        decode_execute_if.arith.csr_imm_value             <= '0;
        decode_execute_if.arith.instr                     <= '0;
        //Exceptions
        decode_execute_if.arith.illegal_insn              <= '0;
        decode_execute_if.arith.breakpoint                <= '0;
        decode_execute_if.arith.ecall_insn                <= '0;
        decode_execute_if.arith.ret_insn                  <= '0;
        decode_execute_if.arith.token                     <= '0;
        decode_execute_if.arith.mal_insn                  <= '0;
        decode_execute_if.arith.fault_insn                <= '0;
        decode_execute_if.arith.wfi                       <= '0;
    end else begin
      if (((hazard_if.id_ex_flush | hazard_if.stall_au) & hazard_if.pc_en) | halt) begin
        decode_execute_if.arith.aluop <= aluop_t'(0);
        decode_execute_if.arith.port_a <= 0;
        decode_execute_if.arith.port_b <= 0;
        //JUMP
        decode_execute_if.arith.jump_instr                <= '0;
        decode_execute_if.arith.j_base                    <= '0;
        decode_execute_if.arith.j_offset                  <= '0;
        decode_execute_if.arith.j_sel                     <= '0;
        //BRANCH
        decode_execute_if.arith.br_imm_sb                 <= '0;
        decode_execute_if.arith.br_branch_type            <= '0;
        //BRANCH PREDICTOR UPDATE
        decode_execute_if.arith.branch_instr              <= '0;
        decode_execute_if.arith.prediction                <= '0;
        decode_execute_if.arith.pc                        <= '0;
        decode_execute_if.arith.pc4                       <= '0;
        //csr
        decode_execute_if.arith.csr_instr                 <= '0;
        decode_execute_if.arith.csr_swap                  <= '0;
        decode_execute_if.arith.csr_clr                   <= '0;
        decode_execute_if.arith.csr_set                   <= '0;
        decode_execute_if.arith.csr_addr                  <= '0;
        decode_execute_if.arith.csr_imm                   <= '0;
        decode_execute_if.arith.csr_imm_value             <= '0;
        decode_execute_if.arith.instr                     <= '0;
        //Exceptions
        decode_execute_if.arith.illegal_insn              <= '0;
        decode_execute_if.arith.breakpoint                <= '0;
        decode_execute_if.arith.ecall_insn                <= '0;
        decode_execute_if.arith.ret_insn                  <= '0;
        decode_execute_if.arith.token                     <= '0;
        decode_execute_if.arith.mal_insn                  <= '0;
        decode_execute_if.arith.fault_insn                <= '0;
        decode_execute_if.arith.wfi                       <= '0;

      end else if(hazard_if.pc_en & ~hazard_if.stall_au) begin
        decode_execute_if.arith.aluop <= cu_if.alu_op;
        decode_execute_if.arith.port_a <= next_port_a;
        decode_execute_if.arith.port_b <= next_port_b;

        //JUMP
        decode_execute_if.arith.jump_instr                <= cu_if.jump;
        decode_execute_if.arith.j_base                    <= base;
        decode_execute_if.arith.j_offset                  <= offset;
        decode_execute_if.arith.j_sel                     <= cu_if.j_sel;
        //BRANCH
        decode_execute_if.arith.br_imm_sb                 <= cu_if.imm_SB;
        decode_execute_if.arith.br_branch_type            <= cu_if.branch_type;
        //BRANCH PREDICTOR UPDATE
        decode_execute_if.arith.branch_instr              <= cu_if.branch;
        decode_execute_if.arith.prediction                <= fetch_decode_if.prediction;
        decode_execute_if.arith.pc                        <= fetch_decode_if.pc;
        decode_execute_if.arith.pc4                       <= fetch_decode_if.pc4;
                //csr
        decode_execute_if.arith.csr_instr                 <= (cu_if.opcode == SYSTEM);
        decode_execute_if.arith.csr_swap                  <= cu_if.csr_swap;
        decode_execute_if.arith.csr_clr                   <= cu_if.csr_clr;
        decode_execute_if.arith.csr_set                   <= cu_if.csr_set;
        decode_execute_if.arith.csr_addr                  <= cu_if.csr_addr;
        decode_execute_if.arith.csr_imm                   <= cu_if.csr_imm;
        decode_execute_if.arith.csr_imm_value             <= {27'h0, cu_if.zimm};
        decode_execute_if.arith.instr                     <= fetch_decode_if.instr;
        //Exceptions
        decode_execute_if.arith.illegal_insn              <= cu_if.illegal_insn;
        decode_execute_if.arith.breakpoint                <= cu_if.breakpoint;
        decode_execute_if.arith.ecall_insn                <= cu_if.ecall_insn;
        decode_execute_if.arith.ret_insn                  <= cu_if.ret_insn;
        decode_execute_if.arith.token                     <= fetch_decode_if.token;
        decode_execute_if.arith.mal_insn                  <= fetch_decode_if.mal_insn;
        decode_execute_if.arith.fault_insn                <= fetch_decode_if.fault_insn;
        decode_execute_if.arith.wfi                       <= cu_if.wfi;
        decode_execute_if.w_src                           <= cu_if.w_src;

        decode_execute_if.arith.wdata_au            <= next_reg_file_wdata;
        decode_execute_if.wen_au                       <= cu_if.wen; //Writeback to register file
        decode_execute_if.reg_rd_au                      <= cu_if.reg_rd; //Writeback to register file

      end
    end
  end



always @(posedge CLK, negedge nRST) begin : LOADSTORE_UNIT
    if (~nRST) begin
      //MEMORY
      decode_execute_if.dwen                      <= '0;
      decode_execute_if.dren                      <= '0;
      decode_execute_if.load_type                 <= '0;
      //Fence 
      decode_execute_if.ifence                    <= '0;
      decode_execute_if.opcode                    <= '0;
    end else begin
      if (((hazard_if.id_ex_flush | hazard_if.stall_ls) & hazard_if.pc_en) | halt) begin
        //MEMORY
        decode_execute_if.dwen                      <= '0;
        decode_execute_if.dren                      <= '0;
        decode_execute_if.load_type                 <= '0;
        //Fence 
        decode_execute_if.ifence                    <= '0;
        decode_execute_if.opcode                    <= '0;
      end else if(hazard_if.pc_en & ~hazard_if.stall_ls) begin
        //MEMORY
        decode_execute_if.dwen                      <= cu_if.dwen; 
        decode_execute_if.dren                      <= cu_if.dren; 
        decode_execute_if.load_type                 <= cu_if.load_type;
        //Fence 
        decode_execute_if.ifence                    <= cu_if.ifence;
        decode_execute_if.opcode                    <= cu_if.opcode;
      end
    end
  end

endmodule