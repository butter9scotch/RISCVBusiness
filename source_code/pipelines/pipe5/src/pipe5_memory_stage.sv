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

`include "pipe5_mem_writeback_if.vh"
`include "pipe5_execute_mem_if.vh"
`include "pipe5_forwarding_unit_if.vh"
`include "generic_bus_if.vh"
`include "cache_control_if.vh"
`include "predictor_pipeline_if.vh"
`include "pipe5_hazard_unit_if.vh"
`include "component_selection_defines.vh"
`include "prv_pipeline_if.vh"


module pipe5_memory_stage(
  input logic CLK, nRST,halt,
  pipe5_execute_mem_if.memory execute_mem_if,
  pipe5_mem_writeback_if.memory mem_wb_if,
  pipe5_forwarding_unit_if.memory bypass_if,
  generic_bus_if.cpu dgen_bus_if,
  predictor_pipeline_if.update predict_if,
  pipe5_hazard_unit_if.memory hazard_if,
  prv_pipeline_if.pipe  prv_pipe_if,
  cache_control_if.pipeline cc_if
);

  import rv32i_types_pkg::*;

  
  word_t store_swapped, wdata;
  word_t latest_valid_pc, valid_pc;
  logic illegal_braddr, illegal_jaddr;

  /*******************************************************
  *** Choose the Endianness Coming into the processor
  *******************************************************/
  logic [3:0] byte_en, byte_en_temp;
  assign byte_en_temp = execute_mem_if.byte_en_temp;
  generate
    if (BUS_ENDIANNESS == "big")
    begin
        assign byte_en = byte_en_temp;
    end else if (BUS_ENDIANNESS == "little")
    begin
      assign byte_en = execute_mem_if.dren ? byte_en_temp :
              {byte_en_temp[0], byte_en_temp[1],
              byte_en_temp[2], byte_en_temp[3]};
    end
  endgenerate 

  word_t dload_ext;
  dmem_extender dmem_ext (
    .dmem_in(wdata),
    .load_type(execute_mem_if.load_type),
    .byte_en(byte_en),
    .ext_out(dload_ext)
  );

  /*******************************************************
  *** Branch Target Resolution and Associated Logic 
  *******************************************************/
  assign hazard_if.brj_addr   = ( execute_mem_if.jump_instr) ? execute_mem_if.jump_addr : execute_mem_if.br_resolved_addr;
  assign hazard_if.mispredict = execute_mem_if.prediction ^ execute_mem_if.branch_taken;
  assign hazard_if.branch     = execute_mem_if.branch_instr; 
  assign hazard_if.jump       = execute_mem_if.jump_instr; 
  /*******************************************************
  *** mal_addr  and Associated Logic 
  *******************************************************/
  logic mal_addr;

  always_comb begin
    if(byte_en == 4'hf) 
      mal_addr = (execute_mem_if.memory_addr[1:0] != 2'b00);
    else if (byte_en == 4'h3 || byte_en == 4'hc) begin
      mal_addr = (execute_mem_if.memory_addr[1:0] == 2'b01 || execute_mem_if.memory_addr[1:0] == 2'b11);
    end
    else 
      mal_addr = 1'b0;
  end

  assign hazard_if.d_mem_busy = dgen_bus_if.busy;
  assign hazard_if.dren    = dgen_bus_if.ren;
  assign hazard_if.dwen    = dgen_bus_if.wen;

  /*******************************************************
  *** data bus  and Associated Logic 
  *******************************************************/
  assign dgen_bus_if.ren     = execute_mem_if.dren & ~mal_addr;
  assign dgen_bus_if.wen     = execute_mem_if.dwen & ~mal_addr;
  assign dgen_bus_if.byte_en = byte_en;
  assign dgen_bus_if.addr    = execute_mem_if.memory_addr;
  always_comb begin
    dgen_bus_if.wdata = '0;
      case(execute_mem_if.load_type) // load_type can be used for store_type as well
        LB: dgen_bus_if.wdata = {4{execute_mem_if.store_wdata[7:0]}};
        LH: dgen_bus_if.wdata = {2{execute_mem_if.store_wdata[15:0]}};
        LW: dgen_bus_if.wdata = execute_mem_if.store_wdata; 
      endcase
  end
 
  /*******************************************************
  *** Branch predictor update logic 
  *******************************************************/
  assign predict_if.update_predictor = execute_mem_if.branch_instr;
  assign predict_if.prediction       = execute_mem_if.prediction;
  assign predict_if.update_addr      = execute_mem_if.br_resolved_addr;
  assign predict_if.branch_result   = execute_mem_if.branch_taken;
  
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
      ifence_reg <= execute_mem_if.ifence;
  end
  
  assign ifence_pulse = execute_mem_if.ifence && ~ifence_reg;
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
  assign hazard_if.ifence = execute_mem_if.ifence;
  assign hazard_if.ifence_pc = execute_mem_if.pc;


  /*******************************************************
  *** Forwading Logic 
  *******************************************************/

  assign bypass_if.rd_mem       = execute_mem_if.reg_rd;
  assign bypass_if.WEN_mem      = execute_mem_if.wen;
  assign bypass_if.rd_data_mem  = (execute_mem_if.lui_instr) ? execute_mem_if.reg_file_wdata: execute_mem_if.alu_port_out;

  /*******************************************************
  *** CSR / Priv Interface Logic 
  *******************************************************/ 
  assign hazard_if.csr     = execute_mem_if.csr_instr;
  assign prv_pipe_if.swap  = execute_mem_if.csr_swap;
  assign prv_pipe_if.clr   = execute_mem_if.csr_clr;
  assign prv_pipe_if.set   = execute_mem_if.csr_set;
  assign prv_pipe_if.wdata = execute_mem_if.csr_wdata;
  assign prv_pipe_if.addr  = execute_mem_if.csr_addr;
  assign prv_pipe_if.valid_write = (prv_pipe_if.swap | prv_pipe_if.clr | prv_pipe_if.set); 
  assign prv_pipe_if.instr = (execute_mem_if.instr != '0);
  assign hazard_if.csr_pc = execute_mem_if.pc;
   
  logic csr_reg, csr_pulse;
  word_t csr_rdata;
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
      csr_reg <= 1'b0;
    else 
      csr_reg <= execute_mem_if.csr_instr;
  end
  
  assign csr_pulse = execute_mem_if.csr_instr && ~csr_reg;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST)
        csr_rdata <= 'h0;
    else if (csr_pulse)
        csr_rdata <= prv_pipe_if.rdata;
  end
  
  /*******************************************************
  *** Exceptions and interrupts & associated logic
  *******************************************************/ 
  
  assign hazard_if.illegal_insn = execute_mem_if.illegal_insn &  prv_pipe_if.invalid_csr; //Illegal Opcode
  assign hazard_if.mal_insn     = execute_mem_if.mal_insn | illegal_jaddr | illegal_braddr; //Instruction not loaded from PC+4
  assign hazard_if.fault_insn   = execute_mem_if.fault_insn; //assigned 1'b0
  assign hazard_if.fault_l      = 1'b0; 
  assign hazard_if.mal_l        =  execute_mem_if.dren & mal_addr;
  assign hazard_if.fault_s      =  1'b0;
  assign hazard_if.mal_s        =  execute_mem_if.dwen & mal_addr;
  assign hazard_if.breakpoint   =  execute_mem_if.breakpoint;
  assign hazard_if.env_m        =  execute_mem_if.ecall_insn;
  assign hazard_if.ret          =  execute_mem_if.ret_insn;
  assign hazard_if.badaddr_d    =  execute_mem_if.memory_addr;//bad addr -data memory
  assign hazard_if.badaddr_i    =  execute_mem_if.pc;// bad addr - instr memory

  assign hazard_if.epc          =  (valid_pc) ? execute_mem_if.pc : latest_valid_pc;
  assign hazard_if.token        =  execute_mem_if.token; 
  assign hazard_if.intr_taken   =  execute_mem_if.intr_seen ;
  assign illegal_jaddr = (execute_mem_if.jump_instr & (execute_mem_if.jump_addr[1:0] != 2'b00));
  assign illegal_braddr = (execute_mem_if.branch_instr & (execute_mem_if.br_resolved_addr[1:0] != 2'b00));

  assign valid_pc = (execute_mem_if.opcode != opcode_t'('h0));

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) 
          latest_valid_pc <= 'h0;
    else begin
        if (halt) 
          latest_valid_pc <= 'h0;
        else if(hazard_if.pc_en & valid_pc) 
            latest_valid_pc  <= execute_mem_if.pc;
      end
  end

  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
          mem_wb_if.reg_file_wdata     <= 'h0;
          mem_wb_if.wen                <= 'h0;
          mem_wb_if.w_src              <= 'h0; 
          mem_wb_if.dload_ext          <= 'h0;
          mem_wb_if.alu_port_out       <= 'h0;
          mem_wb_if.reg_rd             <= 'h0;
          mem_wb_if.halt_instr         <= 'h0;
          mem_wb_if.csr_instr          <= 'h0;
          mem_wb_if.pc                 <= 'h0;
          mem_wb_if.pc4                <= 'h0;
          mem_wb_if.opcode             <= opcode_t'('h0);
          wdata                        <= 'h0;
          mem_wb_if.csr_rdata          <= 'h0;
          mem_wb_if.funct3             <= 'h0; 
          mem_wb_if.funct12            <= 'h0; 
          mem_wb_if.imm_S              <= 'h0; 
          mem_wb_if.imm_I              <= 'h0; 
          mem_wb_if.imm_U              <= 'h0; 
          mem_wb_if.imm_UJ_ext         <= 'h0; 
          mem_wb_if.imm_SB             <= 'h0; 
          mem_wb_if.instr_30           <= 'h0; 
          mem_wb_if.rs1                <= 'h0; 
          mem_wb_if.rs2                <= 'h0; 
          mem_wb_if.instr              <= 'h0; 
      end
      else begin
        if (halt) begin
            mem_wb_if.reg_file_wdata     <= 'h0;
            mem_wb_if.wen                <= 'h0;
            mem_wb_if.w_src              <= 'h0; 
            mem_wb_if.dload_ext          <= 'h0;
            mem_wb_if.alu_port_out       <= 'h0;
            mem_wb_if.reg_rd             <= 'h0;
            mem_wb_if.halt_instr         <= 'h0;
            mem_wb_if.csr_instr          <= 'h0;
            mem_wb_if.pc                 <= 'h0;
            mem_wb_if.pc4                <= 'h0;
            mem_wb_if.opcode             <= opcode_t'('h0);
            wdata                        <= 'h0;
            mem_wb_if.csr_rdata          <= 'h0;
            mem_wb_if.funct3             <= 'h0; 
            mem_wb_if.funct12            <= 'h0; 
            mem_wb_if.imm_S              <= 'h0; 
            mem_wb_if.imm_I              <= 'h0; 
            mem_wb_if.imm_U              <= 'h0; 
            mem_wb_if.imm_UJ_ext         <= 'h0; 
            mem_wb_if.imm_SB             <= 'h0; 
            mem_wb_if.instr_30           <= 'h0; 
            mem_wb_if.rs1                <= 'h0; 
            mem_wb_if.rs2                <= 'h0; 
            mem_wb_if.instr              <= 'h0; 
        end 
        else if (~dgen_bus_if.busy) begin
            //To latch the load instruction data on dcache's busy going low
            wdata     <= dgen_bus_if.rdata;
        end
        else if(hazard_if.pc_en) begin
            //Writeback
            mem_wb_if.reg_file_wdata     <= execute_mem_if.reg_file_wdata;
            mem_wb_if.wen                <= execute_mem_if.wen;
            mem_wb_if.w_src              <= execute_mem_if.w_src;
            mem_wb_if.dload_ext          <= dload_ext;
            mem_wb_if.alu_port_out       <= execute_mem_if.alu_port_out;
            //Forwarding
            mem_wb_if.reg_rd             <= execute_mem_if.reg_rd;
            //Halt
            mem_wb_if.halt_instr         <= execute_mem_if.halt_instr;
            mem_wb_if.pc                 <= execute_mem_if.pc;
            mem_wb_if.pc4                <= execute_mem_if.pc;
            mem_wb_if.opcode             <= execute_mem_if.opcode;
            //CSR
            mem_wb_if.csr_instr          <= execute_mem_if.csr_instr;
            mem_wb_if.csr_rdata          <= csr_rdata;
            //CPU tracker
            mem_wb_if.funct3             <= execute_mem_if.funct3;
            mem_wb_if.funct12            <= execute_mem_if.funct12;
            mem_wb_if.imm_S              <= execute_mem_if.imm_S; 
            mem_wb_if.imm_I              <= execute_mem_if.imm_I; 
            mem_wb_if.imm_U              <= execute_mem_if.imm_U;
            mem_wb_if.imm_UJ_ext         <= execute_mem_if.imm_UJ_ext;
            mem_wb_if.imm_SB             <= execute_mem_if.imm_SB;
            mem_wb_if.instr_30           <= execute_mem_if.instr_30;
            mem_wb_if.rs1                <= execute_mem_if.rs1;
            mem_wb_if.rs2                <= execute_mem_if.rs2;
            mem_wb_if.instr              <= execute_mem_if.instr;
        end
     end
  end
endmodule


