
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
*   Filename:     tspp_execute_stage.sv
*
*   Created by:   Jacob R. Stevens
*   Email:        steven69@purdue.edu
*   Date Created: 06/16/2016
*   Description:  Execute Stage for the Two Stage Pipeline 
*/

`include "pipe5_decode_execute_if.vh"
`include "pipe5_execute_mem_if.vh"
`include "pipe5_forwarding_unit_if.vh"
`include "jump_calc_if.vh"
`include "component_selection_defines.vh"
`include "alu_if.vh"
`include "pipe5_hazard_unit_if.vh"
`include "multiply_unit_if.vh"
`include "divide_unit_if.vh"


module pipe5_execute_stage(
  input logic CLK, nRST,halt,
  pipe5_decode_execute_if.execute decode_execute_if,
  pipe5_execute_mem_if.execute eecute_mem_if,
  pipe5_forwarding_unit_if.execute bypass_if,
  jump_calc_if.execute jump_if,
  pipe5_hazard_unit_if.execute hazard_if,
  branch_res_if.execute branch_if
);

  import rv32i_types_pkg::*;
  import alu_types_pkg::*;
  import pipe5_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  // Interface declarations
  alu_if            alu_if();
  multiply_unit_if  mif();
  divide_unit_if    dif();
 
  alu alu (.*);
  multiply_unit MULU (.*);
  divide_unit DIVU (.*);

  logic [1:0] byte_offset;
  logic [3:0] byte_en_standard;
  word_t w_data, alu_port_b, alu_port_a;
  word_t updated_rs1_data, updated_rs2_data;
  word_t csr_wdata;
  logic intr_taken_ex;
  word_t branch_addr, resolved_addr;


  logic mul_ena, div_ena;
  assign mul_ena = decode_execute_if.sfu_type == MUL_S;
  assign div_ena = decode_execute_if.sfu_type == DIV_S;

  // Assign byte_en based on load type 
  // funct3 for loads and stores are the same bit positions
  // byte_en is valid for both loads and stores 
  assign byte_offset = alu_if.port_out[1:0];

  always_comb begin
    unique case(decode_execute_if.load_type)
      LB : begin
        unique case(byte_offset)
          2'b00   : byte_en_standard = 4'b0001;
          2'b01   : byte_en_standard = 4'b0010;
          2'b10   : byte_en_standard = 4'b0100;
          2'b11   : byte_en_standard = 4'b1000;
          default : byte_en_standard = 4'b0000;
        endcase
      end
      LBU : begin
        unique case(byte_offset)
          2'b00   : byte_en_standard = 4'b0001;
          2'b01   : byte_en_standard = 4'b0010;
          2'b10   : byte_en_standard = 4'b0100;
          2'b11   : byte_en_standard = 4'b1000;
          default : byte_en_standard = 4'b0000;
        endcase
      end
      LH : begin
        unique case(byte_offset)
          2'b00   : byte_en_standard = 4'b0011;
          2'b10   : byte_en_standard = 4'b1100;
          default : byte_en_standard = 4'b0000;
        endcase
      end
      LHU : begin
        unique case(byte_offset)
          2'b00   : byte_en_standard = 4'b0011;
          2'b10   : byte_en_standard = 4'b1100;
          default : byte_en_standard = 4'b0000;
        endcase
      end
      LW:           byte_en_standard = 4'b1111;
      default :     byte_en_standard = 4'b0000;
    endcase
  end

  assign alu_if.port_a = alu_port_a;
  assign alu_if.port_b = alu_port_b;
  assign alu_if.aluop  = decode_execute_if.alu.aluop;

  assign jump_if.base   = (decode_execute_if.j_sel)? decode_execute_if.pc : updated_rs1_data;
  assign jump_if.offset = decode_execute_if.j_offset;
  assign jump_if.j_sel  = decode_execute_if.j_sel;

  assign branch_if.rs1_data    = updated_rs1_data;
  assign branch_if.rs2_data    = updated_rs2_data;
  assign branch_if.pc          = decode_execute_if.pc;
  assign branch_if.imm_sb      = decode_execute_if.br_imm_sb;
  assign branch_if.branch_type = decode_execute_if.br_branch_type;

  assign branch_addr  = branch_if.branch_addr;
  assign resolved_addr = branch_if.branch_taken ? branch_addr : decode_execute_if.pc4;
  

  //Forwading logic
  assign bypass_if.rs1_ex = decode_execute_if.reg_rs1;
  assign bypass_if.rs2_ex = decode_execute_if.reg_rs2;
  assign hazard_if.reg_rd = decode_execute_if.reg_rd;
  assign hazard_if.load   = decode_execute_if.dren;
  assign hazard_if.stall_ex = mif.busy_mu | dif.busy_du;

  assign hazard_if.div_e = 0;
  assign hazard_if.mul_e = 0;
  
//============================MULTIPLY==============================

  word_t mul_alu_port_a;
  word_t mul_alu_port_b;
  
  assign mul_alu_port_a = (decode_execute_if.alu_a_sel == 'd0) ? updated_rs1_data : decode_execute_if.divide.rs1_data;
  assign mul_alu_port_b = (decode_execute_if.alu_b_sel == 'd0) ? updated_rs1_data 
                                          : (decode_execute_if.alu_b_sel == 'd1) ? updated_rs2_data : decode_execute_if.divide.rs2_data;

  assign mif.rs1_data = alu_port_a;
  assign mif.rs2_data = alu_port_b;
  assign mif.start_mu = decode_execute_if.multiply.start_mu;
  assign mif.high_low_sel = decode_execute_if.multiply.high_low_sel;
  assign mif.is_signed = decode_execute_if.multiply.is_signed;
  assign mif.decode_done = decode_execute_if.multiply.decode_done;

//=============================DIVIDE===============================


  word_t div_alu_port_a;
  word_t div_alu_port_b;
  
  assign div_alu_port_a = (decode_execute_if.alu_a_sel == 'd0) ? updated_rs1_data : decode_execute_if.divide.rs1_data;
  assign div_alu_port_b = (decode_execute_if.alu_b_sel == 'd0) ? updated_rs1_data 
                                          : (decode_execute_if.alu_b_sel == 'd1) ? updated_rs2_data : decode_execute_if.divide.rs2_data;
   

  assign dif.rs1_data = div_alu_port_a;
  assign dif.rs2_data = div_alu_port_b;    
  assign dif.start_div = decode_execute_if.divide.start_div;
  assign dif.div_type = decode_execute_if.divide.div_type;
  assign dif.is_signed_div = decode_execute_if.divide.is_signed_div;




//=============================SELECT OUT===============================
  logic [31:0] fu_result;
  logic next_wen;

  always_comb begin
    case (decode_execute_if.sfu_type)
    ARITH_S:begin      
      fu_result = alu_if.port_out; 
      next_wen = decode_execute_if.wen;
      end
    DIV_S:  begin      
      fu_result = dif.wdata_du; 
      next_wen = decode_execute_if.divide.wen;
      end
    MUL_S:  begin      
      fu_result = mif.wdata_mu; 
      next_wen = decode_execute_if.multiply.wen;
      end
    endcase
  end


  always_comb begin
    if (bypass_if.bypass_rs1 == FWD_M)
        updated_rs1_data = bypass_if.rd_data_mem;
    else if (bypass_if.bypass_rs1 == FWD_W)
        updated_rs1_data = bypass_if.rd_data_wb;
    else begin
      case(decode_execute_if.sfu_type)
        ARITH_S:  updated_rs1_data = decode_execute_if.rs1_data;
        MUL_S:    updated_rs1_data = decode_execute_if.multiply.rs1_data;
        DIV_S:    updated_rs1_data = decode_execute_if.divide.rs1_data;
      endcase
    end
  end


  always_comb begin
   if (bypass_if.bypass_rs2 == FWD_M)
       updated_rs2_data = bypass_if.rd_data_mem;
   else if (bypass_if.bypass_rs2 == FWD_W)
       updated_rs2_data = bypass_if.rd_data_wb;
   else begin
       case(decode_execute_if.sfu_type)
        ARITH_S:  updated_rs2_data  = decode_execute_if.rs2_data;
        MUL_S:    updated_rs2_data  = decode_execute_if.multiply.rs2_data;
        DIV_S:    updated_rs2_data  = decode_execute_if.divide.rs2_data;
      endcase
   end
  end

    assign alu_port_a = (decode_execute_if.alu_a_sel == 'd0) ? updated_rs1_data : decode_execute_if.port_a;
    assign alu_port_b = (decode_execute_if.alu_b_sel == 'd0) ? updated_rs1_data 
                                          : (decode_execute_if.alu_b_sel == 'd1) ? updated_rs2_data : decode_execute_if.port_b;
   
    assign csr_wdata = (decode_execute_if.csr_imm) ? decode_execute_if.csr_imm_value : updated_rs1_data;


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



  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST ) begin
          execute_mem_if.reg_file_wdata     <='h0;
          execute_mem_if.w_src              <='h0; 
          execute_mem_if.wen                <='h0; 
          execute_mem_if.dwen               <='h0; 
          execute_mem_if.dren               <='h0; 
          execute_mem_if.store_wdata        <='h0; 
          execute_mem_if.load_type          <=load_t'('h0); 
          execute_mem_if.memory_addr        <='h0; 
          execute_mem_if.byte_en_temp       <='h0; 
          execute_mem_if.jump_instr         <='h0;
          execute_mem_if.jump_addr          <='h0;
          execute_mem_if.lui_instr          <='h0;
          execute_mem_if.branch_instr       <='h0; 
          execute_mem_if.branch_taken       <='h0;
          execute_mem_if.prediction         <='h0;
          execute_mem_if.br_resolved_addr   <='h0;
          execute_mem_if.pc                 <='h0;
          execute_mem_if.pc4                <='h0;
          execute_mem_if.ifence             <='h0;
          execute_mem_if.halt_instr         <='h0; 
          execute_mem_if.csr_instr          <='h0; 
          execute_mem_if.reg_rd             <='h0; 
          execute_mem_if.alu_port_out       <='h0;
          execute_mem_if.opcode             <=opcode_t'('h0);
          execute_mem_if.csr_instr          <= 'h0;
          execute_mem_if.csr_swap           <= 'h0;
          execute_mem_if.csr_clr            <= 'h0;
          execute_mem_if.csr_set            <= 'h0;
          execute_mem_if.csr_addr           <= csr_addr_t'('h0);
          execute_mem_if.instr              <= 'h0;
          execute_mem_if.csr_wdata          <= 'h0;
          execute_mem_if.illegal_insn       <= 'h0;
          execute_mem_if.breakpoint         <= 'h0;
          execute_mem_if.ecall_insn         <= 'h0;
          execute_mem_if.ret_insn           <= 'h0;
          execute_mem_if.token              <= 'h0;
          execute_mem_if.mal_insn           <= 'h0;
          execute_mem_if.fault_insn         <= 'h0;
          execute_mem_if.intr_seen          <= 'h0;
          execute_mem_if.wfi                <= 'h0;
          execute_mem_if.funct3             <= 'h0; 
          execute_mem_if.funct12            <= 'h0 ;
          execute_mem_if.imm_S              <= 'h0 ;
          execute_mem_if.imm_I              <= 'h0 ;
          execute_mem_if.imm_U              <= 'h0 ;
          execute_mem_if.imm_UJ_ext         <= 'h0 ;
          execute_mem_if.imm_SB             <= 'h0 ;
          execute_mem_if.instr_30           <= 'h0 ;
          execute_mem_if.rs1                <= 'h0 ;
          execute_mem_if.rs2                <= 'h0 ;
    end
    else begin
        if (hazard_if.ex_mem_flush && hazard_if.pc_en || halt ) begin
          execute_mem_if.reg_file_wdata     <='h0;
          execute_mem_if.w_src              <='h0; 
          execute_mem_if.wen                <='h0; 
          execute_mem_if.dwen               <='h0; 
          execute_mem_if.dren               <='h0; 
          execute_mem_if.store_wdata        <='h0; 
          execute_mem_if.load_type          <=load_t'('h0); 
          execute_mem_if.memory_addr        <='h0; 
          execute_mem_if.byte_en_temp       <='h0; 
          execute_mem_if.jump_instr         <='h0;
          execute_mem_if.jump_addr          <='h0;
          execute_mem_if.lui_instr          <='h0;
          execute_mem_if.branch_instr       <='h0; 
          execute_mem_if.branch_taken       <='h0;
          execute_mem_if.prediction         <='h0;
          execute_mem_if.br_resolved_addr   <='h0;
          execute_mem_if.pc                 <='h0;
          execute_mem_if.pc4                <='h0;
          execute_mem_if.ifence             <='h0;
          execute_mem_if.halt_instr         <='h0; 
          execute_mem_if.csr_instr          <='h0; 
          execute_mem_if.reg_rd             <='h0; 
          execute_mem_if.alu_port_out       <='h0;
          execute_mem_if.opcode             <= opcode_t'('h0);
          execute_mem_if.csr_instr          <= 'h0;
          execute_mem_if.csr_swap           <= 'h0;
          execute_mem_if.csr_clr            <= 'h0;
          execute_mem_if.csr_set            <= 'h0;
          execute_mem_if.csr_addr           <= csr_addr_t'('h0);
          execute_mem_if.instr              <= 'h0;
          execute_mem_if.csr_wdata          <= 'h0;
          execute_mem_if.illegal_insn       <= 'h0;
          execute_mem_if.breakpoint         <= 'h0;
          execute_mem_if.ecall_insn         <= 'h0;
          execute_mem_if.ret_insn           <= 'h0;
          execute_mem_if.token              <= 'h0;
          execute_mem_if.mal_insn           <= 'h0;
          execute_mem_if.fault_insn         <= 'h0;
          execute_mem_if.intr_seen          <= 'h0;
          execute_mem_if.wfi                <= 'h0;
          execute_mem_if.funct3             <= 'h0; 
          execute_mem_if.funct12            <= 'h0;
          execute_mem_if.imm_S              <= 'h0;
          execute_mem_if.imm_I              <= 'h0;
          execute_mem_if.imm_U              <= 'h0;
          execute_mem_if.imm_UJ_ext         <= 'h0;
          execute_mem_if.imm_SB             <= 'h0;
          execute_mem_if.instr_30           <= 'h0;
          execute_mem_if.rs1                <= 'h0;
          execute_mem_if.rs2                <= 'h0;
        end
        else if (hazard_if.dmem_access & ~hazard_if.d_mem_busy) begin //arbitate dren, dwen for iaccess
          execute_mem_if.dwen               <='h0; 
          execute_mem_if.dren               <='h0; 
        end
        else if(hazard_if.pc_en ) begin
          //Writeback
          execute_mem_if.reg_file_wdata     <= decode_execute_if.reg_file_wdata;
          execute_mem_if.w_src              <= decode_execute_if.w_src;
          execute_mem_if.wen                <= next_wen;
          //Mem Signals
          execute_mem_if.dwen               <= decode_execute_if.dwen;
          execute_mem_if.dren               <= decode_execute_if.dren;
          execute_mem_if.store_wdata        <= updated_rs2_data;
          execute_mem_if.load_type          <= decode_execute_if.load_type;
          execute_mem_if.memory_addr        <= alu_if.port_out;
          execute_mem_if.byte_en_temp       <= byte_en_standard;
          //Jump Resolution
          execute_mem_if.jump_instr         <= decode_execute_if.jump_instr;
          execute_mem_if.jump_addr          <= jump_if.jump_addr;
          execute_mem_if.lui_instr          <='h0;
          //Branch Resolution
          execute_mem_if.branch_instr       <= decode_execute_if.branch_instr;
          execute_mem_if.branch_taken       <= branch_if.branch_taken;
          execute_mem_if.prediction         <= decode_execute_if.prediction;
          execute_mem_if.br_resolved_addr   <= resolved_addr;
          execute_mem_if.pc                 <= decode_execute_if.pc;
          execute_mem_if.pc4                <= decode_execute_if.pc4;
          //fence
          execute_mem_if.ifence             <= decode_execute_if.ifence;
          //Halt
          execute_mem_if.halt_instr         <= decode_execute_if.halt_instr;
          //Forwarding
          execute_mem_if.reg_rd             <= decode_execute_if.reg_rd;
          execute_mem_if.alu_port_out       <= fu_result;
          execute_mem_if.opcode             <= decode_execute_if.opcode;
          execute_mem_if.lui_instr          <= decode_execute_if.lui_instr;
          //CSR
          execute_mem_if.csr_instr          <= decode_execute_if.csr_instr; 
          execute_mem_if.csr_swap           <= decode_execute_if.csr_swap;
          execute_mem_if.csr_clr            <= decode_execute_if.csr_clr;
          execute_mem_if.csr_set            <= decode_execute_if.csr_set;
          execute_mem_if.csr_addr           <= decode_execute_if.csr_addr;
          execute_mem_if.csr_wdata          <= csr_wdata;
          execute_mem_if.instr              <= decode_execute_if.instr;
          //Exceptions
          execute_mem_if.illegal_insn       <= decode_execute_if.illegal_insn;
          execute_mem_if.breakpoint         <= decode_execute_if.breakpoint;
          execute_mem_if.ecall_insn         <= decode_execute_if.ecall_insn;
          execute_mem_if.ret_insn           <= decode_execute_if.ret_insn;
          execute_mem_if.token              <= 1'b1;
          execute_mem_if.mal_insn           <= decode_execute_if.mal_insn;
          execute_mem_if.fault_insn         <= decode_execute_if.fault_insn;
          execute_mem_if.intr_seen          <= intr_taken_ex;
          execute_mem_if.wfi                <= decode_execute_if.wfi;
          //CPU tracker
          execute_mem_if.funct3             <= decode_execute_if.funct3;
          execute_mem_if.funct12            <= decode_execute_if.funct12;
          execute_mem_if.imm_S              <= decode_execute_if.imm_S; 
          execute_mem_if.imm_I              <= decode_execute_if.imm_I; 
          execute_mem_if.imm_U              <= decode_execute_if.imm_U;
          execute_mem_if.imm_UJ_ext         <= decode_execute_if.imm_UJ_ext;
          execute_mem_if.imm_SB             <= decode_execute_if.imm_SB;
          execute_mem_if.instr_30           <= decode_execute_if.instr_30;
          execute_mem_if.rs1                <= decode_execute_if.reg_rs1;
          execute_mem_if.rs2                <= decode_execute_if.reg_rs2;
         end
      end
  end

endmodule