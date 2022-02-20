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

`include "pipe5_fetch2_decode_if.vh"
`include "pipe5_decode_execute_if.vh"
`include "control_unit_if.vh"
`include "component_selection_defines.vh"
`include "rv32i_reg_file_if.vh"
`include "pipe5_hazard_unit_if.vh"


module pipe5_decode_stage (
  input logic CLK, nRST, halt,
  pipe5_fetch2_decode_if.decode fetch_decode_if,
  pipe5_decode_execute_if.decode decode_execute_if,
  rv32i_reg_file_if.decode rf_if,
  pipe5_hazard_unit_if.decode hazard_if
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
    //.rf_if(rf_if)
   // .rmgmt_rsel_s_0(rm_if.rsel_s_0),
   // .rmgmt_rsel_s_1(rm_if.rsel_s_1),
   // .rmgmt_rsel_d(rm_if.rsel_d),
   // .rmgmt_req_reg_r(rm_if.req_reg_r),
   // .rmgmt_req_reg_w(rm_if.req_reg_w)
  );

  logic mul_ena, div_ena;
  assign mul_ena = cu_if.sfu_type == MUL_S;
  assign div_ena = cu_if.sfu_type == DIV_S;


  /*******************************************************
  * Reg File Logic
  *******************************************************/
   assign rf_if.rs1 = cu_if.reg_rs1;
   assign rf_if.rs2 = cu_if.reg_rs2;

  /*******************************************************
  * MISC RISC-MGMT Logic
  *******************************************************/

  //assign rm_if.rdata_s_0 = rf_if.rs1_data;
  //assign rm_if.rdata_s_1 = rf_if.rs2_data;


  assign cu_if.instr = fetch_decode_if.instr;
  //assign rm_if.insn  = fetch_decode_if.instr;

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
  word_t imm_or_shamt, next_port_a, next_port_b, w_data;
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
    //if(rm_if.req_reg_w) begin 
    //  w_data = rm_if.reg_wdata;
    //end 
    //else begin
      case(cu_if.w_sel)
        3'd1    : w_data = fetch_decode_if.pc4;
        3'd2    : w_data = cu_if.imm_U;
        default : w_data = '0; 
      endcase
   // end
  end
 
  
  /*******************************************************
  *** Hazard unit connection  
  *******************************************************/

  assign hazard_if.halt = cu_if.halt;
  assign hazard_if.reg_rs1 = rf_if.rs1;
  assign hazard_if.reg_rs2 = rf_if.rs2;

  /*********************************************************
  *** SparCE Module Logic
  *********************************************************/
  /*assign sparce_if.wb_data    = rf_if.w_data;
  assign sparce_if.wb_en      = rf_if.wen;
  assign sparce_if.sasa_data  = rf_if.rs2_data;
  assign sparce_if.sasa_addr  = alu_if.port_out;
  assign sparce_if.sasa_wen   = cu_if.dwen;
  assign sparce_if.rd         = rf_if.rd;*/
  
  /*********************************************************
  *** Signals for Bind Tracking - Read-Only, These don't affect execution
  *********************************************************/
  assign funct3 = cu_if.instr[14:12];
  assign funct12 = cu_if.instr[31:20];
  assign instr_30 = cu_if.instr[30];

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        decode_execute_if.alu_a_sel                 <='h0; 
        decode_execute_if.alu_b_sel                 <='h0; 
        decode_execute_if.reg_rs1                   <='h0; 
        decode_execute_if.reg_rs2                   <='h0; 
        decode_execute_if.reg_rd                    <='h0; 
        decode_execute_if.port_a                    <='h0; 
        decode_execute_if.port_b                    <='h0; 
        decode_execute_if.rs1_data                  <='h0; 
        decode_execute_if.rs2_data                  <='h0; 
        decode_execute_if.lui_instr                 <='h0;
        decode_execute_if.reg_file_wdata            <='h0; 
        decode_execute_if.w_sel                     <='h0; 
        decode_execute_if.wen                       <='h0; 
        decode_execute_if.dwen                      <='h0; 
        decode_execute_if.dren                      <='h0; 
        decode_execute_if.load_type                 <=load_t'('h0); 
        decode_execute_if.jump_instr                <='h0; 
        decode_execute_if.j_base                    <='h0; 
        decode_execute_if.j_offset                  <='h0; 
        decode_execute_if.j_sel                     <='h0; 
        decode_execute_if.br_imm_sb                 <='h0; 
        decode_execute_if.br_branch_type            <=branch_t'('h0); 
        decode_execute_if.branch_instr              <='h0; 
        decode_execute_if.prediction                <='h0;
        decode_execute_if.halt_instr                <='h0; 
        decode_execute_if.ifence                    <='h0;
        decode_execute_if.pc                        <='h0;
        decode_execute_if.pc4                       <='h0;
        decode_execute_if.opcode                    <=opcode_t'('h0);
        decode_execute_if.csr_instr                 <= 'h0;
        decode_execute_if.csr_swap                  <= 'h0;
        decode_execute_if.csr_clr                   <= 'h0;
        decode_execute_if.csr_set                   <= 'h0;
        decode_execute_if.csr_addr                  <= csr_addr_t'('h0);
        decode_execute_if.csr_imm                   <= 'h0;
        decode_execute_if.csr_imm_value             <= 'h0;
        decode_execute_if.instr                     <= 'h0;
        decode_execute_if.illegal_insn              <= 'h0; 
        decode_execute_if.breakpoint                <= 'h0; 
        decode_execute_if.ecall_insn                <= 'h0; 
        decode_execute_if.ret_insn                  <= 'h0; 
        decode_execute_if.token                     <= 'h0; 
        decode_execute_if.mal_insn                  <= 'h0; 
        decode_execute_if.fault_insn                <= 'h0;
        decode_execute_if.wfi                       <= 'h0;
        decode_execute_if.funct3                    <= 'h0; 
        decode_execute_if.funct12                   <= 'h0;
        decode_execute_if.imm_S                     <= 'h0;
        decode_execute_if.imm_I                     <= 'h0;
        decode_execute_if.imm_U                     <= 'h0;
        decode_execute_if.imm_UJ_ext                <= 'h0;
        decode_execute_if.imm_SB                    <= 'h0;
        decode_execute_if.instr_30                  <= 'h0;
    end 
    else begin 
        if (((hazard_if.id_ex_flush | hazard_if.stall) & hazard_if.pc_en) | halt) begin
            decode_execute_if.alu_a_sel                 <='h0; 
            decode_execute_if.alu_b_sel                 <='h0; 
            decode_execute_if.reg_rs1                   <='h0; 
            decode_execute_if.reg_rs2                   <='h0; 
            decode_execute_if.reg_rd                    <='h0; 
            decode_execute_if.port_a                    <='h0; 
            decode_execute_if.port_b                    <='h0; 
            decode_execute_if.rs1_data                  <='h0; 
            decode_execute_if.rs2_data                  <='h0; 
            decode_execute_if.lui_instr                 <='h0;
            decode_execute_if.reg_file_wdata            <='h0; 
            decode_execute_if.w_sel                     <='h0; 
            decode_execute_if.wen                       <='h0; 
            decode_execute_if.dwen                      <='h0; 
            decode_execute_if.dren                      <='h0; 
            decode_execute_if.load_type                 <=load_t'('h0); 
            decode_execute_if.jump_instr                <='h0; 
            decode_execute_if.j_base                    <='h0; 
            decode_execute_if.j_offset                  <='h0; 
            decode_execute_if.j_sel                     <='h0; 
            decode_execute_if.br_imm_sb                 <='h0; 
            decode_execute_if.br_branch_type            <=branch_t'('h0); 
            decode_execute_if.branch_instr              <='h0; 
            decode_execute_if.prediction                <='h0;
            decode_execute_if.halt_instr                <='h0; 
            decode_execute_if.ifence                    <='h0;
            decode_execute_if.pc                        <='h0;
            decode_execute_if.pc4                       <='h0;
            decode_execute_if.opcode                    <=opcode_t'('h0);
            decode_execute_if.csr_instr                 <= 'h0;
            decode_execute_if.csr_swap                  <= 'h0;
            decode_execute_if.csr_clr                   <= 'h0;
            decode_execute_if.csr_set                   <= 'h0;
            decode_execute_if.csr_addr                  <= csr_addr_t'('h0);
            decode_execute_if.csr_imm                   <= 'h0;
            decode_execute_if.csr_imm_value             <= 'h0;
            decode_execute_if.instr                     <= 'h0;
            decode_execute_if.illegal_insn              <= 'h0; 
            decode_execute_if.breakpoint                <= 'h0; 
            decode_execute_if.ecall_insn                <= 'h0; 
            decode_execute_if.ret_insn                  <= 'h0; 
            decode_execute_if.token                     <= 'h0; 
            decode_execute_if.mal_insn                  <= 'h0; 
            decode_execute_if.fault_insn                <= 'h0; 
            decode_execute_if.wfi                       <= 'h0;
            decode_execute_if.funct3                    <= 'h0; 
            decode_execute_if.funct12                   <= 'h0;
            decode_execute_if.imm_S                     <= 'h0;
            decode_execute_if.imm_I                     <= 'h0;
            decode_execute_if.imm_U                     <= 'h0;
            decode_execute_if.imm_UJ_ext                <= 'h0;
            decode_execute_if.imm_SB                    <= 'h0;
            decode_execute_if.instr_30                  <= 'h0;
        end else if(hazard_if.pc_en & ~hazard_if.stall) begin
            //FORWARDING
            decode_execute_if.alu_a_sel                 <= cu_if.alu_a_sel;
            decode_execute_if.alu_b_sel                 <= cu_if.alu_b_sel;
            decode_execute_if.reg_rs1                   <= rf_if.rs1;
            decode_execute_if.reg_rs2                   <= rf_if.rs2;
            decode_execute_if.reg_rd                    <= cu_if.reg_rd;
            decode_execute_if.rs1_data                  <= rf_if.rs1_data;
            decode_execute_if.rs2_data                  <= rf_if.rs2_data;
            decode_execute_if.lui_instr                 <= cu_if.lui_instr;
            //ALU
            decode_execute_if.port_a                    <= next_port_a;
            decode_execute_if.port_b                    <= next_port_b;
            //REG_FILE/ WRITEBACK
            decode_execute_if.reg_file_wdata            <= w_data;
            decode_execute_if.w_sel                     <= cu_if.w_sel;
            decode_execute_if.wen                       <= cu_if.wen; //Writeback to register file
            //MEMORY
            decode_execute_if.dwen                      <= cu_if.dwen; 
            decode_execute_if.dren                      <= cu_if.dren; 
            decode_execute_if.load_type                 <= cu_if.load_type;
            //JUMP
            decode_execute_if.jump_instr                <= cu_if.jump;
            decode_execute_if.j_base                    <= base;
            decode_execute_if.j_offset                  <= offset;
            decode_execute_if.j_sel                     <= cu_if.j_sel;
            //BRANCH
            decode_execute_if.br_imm_sb                 <= cu_if.imm_SB;
            decode_execute_if.br_branch_type            <= cu_if.branch_type;
            //BRANCH PREDICTOR UPDATE
            decode_execute_if.branch_instr              <= cu_if.branch;
            decode_execute_if.prediction                <= fetch_decode_if.prediction;
            decode_execute_if.pc                        <= fetch_decode_if.pc;
            decode_execute_if.pc4                       <= fetch_decode_if.pc4;
            //HALT
            decode_execute_if.halt_instr                <= cu_if.halt;
            //Fence 
            decode_execute_if.ifence                    <= cu_if.ifence;
            decode_execute_if.opcode                    <= cu_if.opcode;
            //CSR
            decode_execute_if.csr_instr                 <= (cu_if.opcode == SYSTEM);
            decode_execute_if.csr_swap                  <= cu_if.csr_swap;
            decode_execute_if.csr_clr                   <= cu_if.csr_clr;
            decode_execute_if.csr_set                   <= cu_if.csr_set;
            decode_execute_if.csr_addr                  <= cu_if.csr_addr;
            decode_execute_if.csr_imm                   <= cu_if.csr_imm;
            decode_execute_if.csr_imm_value             <= {27'h0, cu_if.zimm};
            decode_execute_if.instr                     <= fetch_decode_if.instr;
            //Exceptions
            decode_execute_if.illegal_insn              <= cu_if.illegal_insn;
            decode_execute_if.breakpoint                <= cu_if.breakpoint;
            decode_execute_if.ecall_insn                <= cu_if.ecall_insn;
            decode_execute_if.ret_insn                  <= cu_if.ret_insn;
            decode_execute_if.token                     <= fetch_decode_if.token;
            decode_execute_if.mal_insn                  <= fetch_decode_if.mal_insn;
            decode_execute_if.fault_insn                <= fetch_decode_if.fault_insn;
            decode_execute_if.wfi                       <= cu_if.wfi;
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

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
          decode_execute_if.sign_type <= SIGNED;
          decode_execute_if.sfu_type <= ARITH_S;
          // decode_execute_if.high_low_sel <= 0;
          decode_execute_if.div_type <= 0;
    end else begin 
        if (((hazard_if.id_ex_flush | hazard_if.stall) & hazard_if.pc_en) | halt) begin
          decode_execute_if.sign_type <= SIGNED;
          decode_execute_if.sfu_type <= ARITH_S;
          // decode_execute_if.high_low_sel <= 0;
          decode_execute_if.div_type <= 0;
        end else if(hazard_if.pc_en & ~hazard_if.stall) begin
          decode_execute_if.sign_type <= cu_if.sign_type;
          decode_execute_if.sfu_type <= cu_if.sfu_type;
          // decode_execute_if.high_low_sel <= cu_if.high_low_sel;
          decode_execute_if.div_type <= cu_if.div_type;
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
      if (((hazard_if.id_ex_flush | hazard_if.stall) & hazard_if.pc_en) | halt) begin
        decode_execute_if.multiply.rs1_data <= 0;
        decode_execute_if.multiply.rs2_data <= 0;
        decode_execute_if.multiply.start_mu <= 0;
        decode_execute_if.multiply.high_low_sel <= 0;
        decode_execute_if.multiply.decode_done <= 0;
        decode_execute_if.multiply.wen <= 0;
        decode_execute_if.multiply.is_signed <= SIGNED;
        decode_execute_if.multiply.reg_rd <= 0;
      end else if(hazard_if.pc_en & ~hazard_if.stall) begin
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
      if (((hazard_if.id_ex_flush | hazard_if.stall) & hazard_if.pc_en) | halt) begin
        decode_execute_if.divide.rs1_data <= 0;
        decode_execute_if.divide.rs2_data <= 0;
        decode_execute_if.divide.start_div <= 0;
        decode_execute_if.divide.div_type <= 0;
        decode_execute_if.divide.is_signed_div <= 0;
        decode_execute_if.divide.wen <= 0;
        decode_execute_if.divide.reg_rd <= 0;
      end else if(hazard_if.pc_en & ~hazard_if.stall) begin
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

  always @(posedge CLK, negedge nRST) begin : ALU
    if (~nRST) begin
        decode_execute_if.alu.aluop <= 0;
        decode_execute_if.alu.port_a <= 0;
        decode_execute_if.alu.port_b <= 0;
    end else begin
      if (((hazard_if.id_ex_flush | hazard_if.stall) & hazard_if.pc_en) | halt) begin
        decode_execute_if.alu.aluop <= aluop_t'(0);
        decode_execute_if.alu.port_a <= 0;
        decode_execute_if.alu.port_b <= 0;
      end else if(hazard_if.pc_en & ~hazard_if.stall) begin
        decode_execute_if.alu.aluop <= cu_if.alu_op;
        decode_execute_if.alu.port_a <= next_port_a;
        decode_execute_if.alu.port_b <= next_port_b;
    end
    end
  end

endmodule