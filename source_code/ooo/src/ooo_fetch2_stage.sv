///*
//*   Copyright 2016 Purdue University
//*   
//*   Licensed under the Apache License, Version 2.0 (the "License");
//*   you may not use this file except in compliance with the License.
//*   You may obtain a copy of the License at
//*   
//*       http://www.apache.org/licenses/LICENSE-2.0
//*   
//*   Unless required by applicable law or agreed to in writing, software
//*   distributed under the License is distributed on an "AS IS" BASIS,
//*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//*   See the License for the specific language governing permissions and
//*   limitations under the License.
//*
//*
//*   Filename:     tspp_fetch_stage.sv
//*
//*   Created by:   John Skubic
//*   Email:        jskubic@purdue.edu
//*   Date Created: 06/19/2016
//*   Description:  Fetch stage for the two stage pipeline
//*/
//
//`include "ooo_fetch1_fetch2_if.vh"
//`include "ooo_fetch2_decode_if.vh"
//`include "generic_bus_if.vh"
//`include "component_selection_defines.vh"
//`include "ooo_hazard_unit_if.vh"
//
//module ooo_fetch2_stage (
  //input logic CLK, nRST,halt,
  //ooo_fetch1_fetch2_if.fetch2 fetch1_fetch2_if,
  //ooo_fetch2_decode_if.fetch fetch_decode_if,
  //ooo_hazard_unit_if.fetch2 hazard_if,
  //generic_bus_if.cpu igen_bus_if
//);
  //import rv32i_types_pkg::*;
//
  //word_t pc, pc4, instr;
  //logic mal_addr;
  //
  ////Gte the current PC from fetch1 stage
  //assign pc = fetch1_fetch2_if.pc;
  //assign pc4 = pc+4;
  //assign mal_addr  = (igen_bus_if.addr[1:0] != 2'b00);
//
  ////Instruction Access logic
  //assign hazard_if.i_mem_busy     = igen_bus_if.busy;
  //assign igen_bus_if.addr         = pc;
  //assign igen_bus_if.ren          = ~halt;
  //assign igen_bus_if.wen          = 1'b0;
  //assign igen_bus_if.byte_en      = 4'b1111;
  //assign igen_bus_if.wdata        = '0;
  //
  ////Fetch Execute Pipeline Signals
  //always_ff @ (posedge CLK, negedge nRST) begin
      //if (!nRST) begin
        //fetch_decode_if.token               <='h0; 
        //fetch_decode_if.pc                  <='h0; 
        //fetch_decode_if.pc4                 <='h0;
        //fetch_decode_if.instr               <='h0; 
        //fetch_decode_if.prediction     <='h0; 
        //fetch_decode_if.mal_insn            <='h0;
        //fetch_decode_if.fault_insn          <= 1'b0;
      //end
      //else begin
        //if (halt) begin
            //fetch_decode_if.token               <='h0; 
            //fetch_decode_if.pc                  <='h0; 
            //fetch_decode_if.pc4                 <='h0;
            //fetch_decode_if.prediction          <='h0; 
            //fetch_decode_if.mal_insn            <='h0;
            //fetch_decode_if.fault_insn          <= 1'b0;
        //end
        //else if (hazard_if.fetch_decode_flush & hazard_if.pc_en) begin
            //fetch_decode_if.token               <='h0; 
            //fetch_decode_if.instr               <='h0; 
            //fetch_decode_if.prediction          <='h0; 
            //fetch_decode_if.mal_insn            <='h0;
            //fetch_decode_if.fault_insn          <= 1'b0;
        //end 
        //else if(hazard_if.pc_en & ~ hazard_if.fetch_decode_flush & ~hazard_if.stall) begin
            //fetch_decode_if.token               <= 1'b1;
            //fetch_decode_if.pc                  <= pc;
            //fetch_decode_if.pc4                 <= pc4;
            //fetch_decode_if.instr               <= instr;
            //fetch_decode_if.prediction          <= fetch1_fetch2_if.prediction;
            ////Exceptions
            //fetch_decode_if.mal_insn            <= mal_addr;
            //fetch_decode_if.fault_insn          <= 1'b0;
        //end
      //end
  //end
//
  //// Choose the endianness of the data coming into the processor
  //generate
    //if (BUS_ENDIANNESS == "big")
      //assign instr = igen_bus_if.rdata;
    //else if (BUS_ENDIANNESS == "little")
      //endian_swapper ltb_endian(igen_bus_if.rdata, instr);  
  //endgenerate
//
//endmodule
//
//
