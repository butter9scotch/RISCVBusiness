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
*   Filename:     ooo_fetch_stage.sv
*
*   Created by:   Nicholas Gildenhuys
*   Email:        ngildenh@purdue.edu
*   Date Created: 06/19/2016
*   Description:  Fetch stage for the out of order pipeline
*/

`include "ooo_fetch_decode_if.vh"
`include "generic_bus_if.vh"
`include "component_selection_defines.vh"
`include "ooo_hazard_unit_if.vh"

module ooo_fetch_stage (
  input logic CLK, nRST,halt, ihit,
  ooo_fetch_decode_if.fetch fetch_decode_if,
  predictor_pipeline_if.access predict_if,
  ooo_hazard_unit_if.fetch hazard_if,
  generic_bus_if.cpu igen_bus_if
);
  import rv32i_types_pkg::*;

  parameter RESET_PC = 32'h8400; //32'h200; //32'h80000000;
  word_t pc, pc4, instr;
  logic mal_addr;
  word_t program_counter_pc;
  word_t next_pc;
  logic take_new_pc; // any special events not pc + 4

  assign hazard_if.pc_fe       = program_counter_pc;

  //Get the current PC from fetch stage
  assign pc4 = program_counter_pc + 4;
  assign mal_addr  = (igen_bus_if.addr[1:0] != 2'b00);
  assign take_new_pc = (predict_if.predict_taken | hazard_if.npc_sel | hazard_if.insert_priv_pc | hazard_if.ifence_flush | hazard_if.csr_flush) & ihit;

  //Instruction Access logic
  assign hazard_if.i_mem_busy     = igen_bus_if.busy;
  assign igen_bus_if.addr         = program_counter_pc;
  assign igen_bus_if.ren          = ~halt; // do this because the read transaction wasn't halting on a new address unless ren went low
  assign igen_bus_if.wen          = 1'b0;
  assign igen_bus_if.byte_en      = 4'b1111;
  assign igen_bus_if.wdata        = '0;


  // program counter main flop
  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      program_counter_pc <= RESET_PC;
      fetch_decode_if.prediction <= '0;
    end else begin
      // normal operation
      if(halt) begin
        // halt case
        program_counter_pc <= RESET_PC;
        fetch_decode_if.prediction <= '0;
      end else if(take_new_pc | hazard_if.pc_en & ~hazard_if.stall_fetch_decode) begin
        // normal operations/incrementation
        program_counter_pc <= next_pc;
        fetch_decode_if.prediction <= predict_if.predict_taken;
      end else begin
        // stall
        program_counter_pc <= program_counter_pc;
        fetch_decode_if.prediction <= fetch_decode_if.prediction;
      end
    end
  end

  // prediction interface logic

  assign predict_if.current_pc = program_counter_pc;
  //Next PC logic
  always_comb begin
    next_pc = pc4;
    if(hazard_if.insert_priv_pc) begin
      next_pc = hazard_if.priv_pc;
    end else if(hazard_if.intr_taken) begin
      next_pc = program_counter_pc;
    end else if(hazard_if.csr_flush) begin
      next_pc = hazard_if.csr_pc + 4;
    end else if(hazard_if.ifence_flush) begin
      next_pc = hazard_if.ifence_pc + 4;
    end else if(hazard_if.npc_sel) begin
      next_pc = hazard_if.brj_addr;
    end else if(predict_if.predict_taken) begin
      next_pc = predict_if.target_addr;
    end else begin
      next_pc = pc4;
    end
  end

  //Fetch Execute Pipeline Signals
  always_ff @ (posedge CLK, negedge nRST) begin
      if (!nRST) begin
        // reset
        fetch_decode_if.token               <='h0;
        fetch_decode_if.pc                  <='h0;
        fetch_decode_if.pc4                 <='h0;
        fetch_decode_if.instr               <='h0;
        // fetch_decode_if.prediction          <='h0;
        fetch_decode_if.mal_insn            <='h0;
        fetch_decode_if.fault_insn          <= 1'b0;
      end else begin
        if (halt) begin
          // halt
            fetch_decode_if.token               <='h0;
            fetch_decode_if.pc                  <='h0;
            fetch_decode_if.pc4                 <='h0;
            // fetch_decode_if.prediction          <='h0;
            fetch_decode_if.mal_insn            <='h0;
            fetch_decode_if.fault_insn          <= 1'b0;
        end else if (hazard_if.fetch_decode_flush | (~hazard_if.pc_en & ~hazard_if.stall_fetch_decode)) begin
          // hazard flush
            fetch_decode_if.token               <='h0;
            fetch_decode_if.instr               <='h0;
            // fetch_decode_if.prediction          <='h0;
            fetch_decode_if.mal_insn            <='h0;
            fetch_decode_if.fault_insn          <= 1'b0;
        end else if(hazard_if.pc_en & ~hazard_if.fetch_decode_flush & ~hazard_if.stall_fetch_decode) begin
          // normal operating conditions
            fetch_decode_if.token               <= 1'b1;
            fetch_decode_if.pc                  <= program_counter_pc;
            fetch_decode_if.pc4                 <= pc4;
            fetch_decode_if.instr               <= instr;
            // fetch_decode_if.prediction          <= predict_if.predict_taken;
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


