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
*   Filename:     tspp_fetch_stage.sv
*
*   Created by:   John Skubic
*   Email:        jskubic@purdue.edu
*   Date Created: 06/19/2016
*   Description:  Fetch stage for the two stage pipeline
*/

`include "pipe5_fetch1_fetch2_if.vh"
`include "pipe5_fetch2_decode_if.vh"
`include "generic_bus_if.vh"
`include "component_selection_defines.vh"
`include "pipe5_hazard_unit_if.vh"

module pipe5_fetch2_stage (
  input logic CLK, nRST,halt,
  pipe5_fetch2_decode_if.fetch fetch_decode_if,
  predictor_pipeline_if.access predict_if,
  pipe5_hazard_unit_if.fetch2 hazard_if,
  generic_bus_if.cpu igen_bus_if
);
  import rv32i_types_pkg::*;

  parameter RESET_PC = 32'h80000000;
  word_t pc, pc4, instr;
  logic mal_addr, prediction;
  
  //Gte the current PC from fetch1 stage
  //assign pc = fetch1_fetch2_if.pc;
  assign pc4 = npc + 4;
  assign mal_addr  = (igen_bus_if.addr[1:0] != 2'b00);

  //Instruction Access logic
  assign hazard_if.i_mem_busy     = igen_bus_if.busy;
  assign igen_bus_if.addr         = program_counter_pc;
  assign igen_bus_if.ren          = ~halt;
  assign igen_bus_if.wen          = 1'b0;
  assign igen_bus_if.byte_en      = 4'b1111;
  assign igen_bus_if.wdata        = '0;


  // program counter main flop
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      program_counter_pc <= RESET_PC;
      prediction <= '0;
    end else begin
      // normal operation
      if(halt) begin
        // halt case
        program_counter_pc <= RESET_PC;
        prediction <= '0;
      end else if((hazard_if.pc_en && ~hazard_if.stall) || hazard_if.insert_priv_pc) begin
        // normal operations/incrementation
        program_counter_pc <= npc;
        prediction <= predict_if.predict_taken;
      end else begin
        // stall
        program_counter_pc <= program_counter_pc;
        prediction <= prediction;
      end
    end
  end

  // prediction interface logic
  assign predict_if.current_pc = program_counter_pc;
  //Next PC logic
  assign npc = hazard_if.insert_priv_pc ? hazard_if.priv_pc : (hazard_if.intr_taken) ? pregram_counter_pc: (hazard_if.csr_flush) ? (hazard_if.csr_pc +'h4): (hazard_if.ifence_flush) ? (hazard_if.ifence_pc +'h4): (hazard_if.npc_sel)? hazard_if. brj_addr : predict_if.predict_taken ? predict_if.target_addr : pc4;

  //Fetch Execute Pipeline Signals
  always_ff @ (posedge CLK, negedge nRST) begin
      if (!nRST) begin
        // reset
        fetch_decode_if.token               <='h0; 
        fetch_decode_if.pc                  <='h0; 
        fetch_decode_if.pc4                 <='h0;
        fetch_decode_if.instr               <='h0; 
        fetch_decode_if.prediction          <='h0; 
        fetch_decode_if.mal_insn            <='h0;
        fetch_decode_if.fault_insn          <= 1'b0;
      end
      else begin
        if (halt) begin
          // halt
            fetch_decode_if.token               <='h0; 
            fetch_decode_if.pc                  <='h0; 
            fetch_decode_if.pc4                 <='h0;
            fetch_decode_if.prediction          <='h0; 
            fetch_decode_if.mal_insn            <='h0;
            fetch_decode_if.fault_insn          <= 1'b0;
        end
        else if (hazard_if.if_id_flush & hazard_if.pc_en) begin
          // hazard flush
            fetch_decode_if.token               <='h0; 
            fetch_decode_if.instr               <='h0; 
            fetch_decode_if.prediction          <='h0; 
            fetch_decode_if.mal_insn            <='h0;
            fetch_decode_if.fault_insn          <= 1'b0;
        end 
        else if(hazard_if.pc_en & ~hazard_if.if_id_flush & ~hazard_if.stall) begin
          // normal operating conditions
            fetch_decode_if.token               <= 1'b1;
            fetch_decode_if.pc                  <= program_counter_pc;
            fetch_decode_if.pc4                 <= pc4;
            fetch_decode_if.instr               <= instr;
            fetch_decode_if.prediction          <= predict_if.predict_taken;
            //Exceptions
            fetch_decode_if.mal_insn            <= mal_addr;
            fetch_decode_if.fault_insn          <= 1'b0;
        end
      end
  end

  //PREDICT_IF interface
  // TODO: only main issue I can se here is the predictor interface pulling
  // from the decode latch instead of the pc. also in this config the PC is 
  // stored in the decode latch??
 
  // Choose the endianness of the data coming into the processor
  generate
    if (BUS_ENDIANNESS == "big")
      assign instr = igen_bus_if.rdata;
    else if (BUS_ENDIANNESS == "little")
      endian_swapper ltb_endian(igen_bus_if.rdata, instr);  
  endgenerate

endmodule


