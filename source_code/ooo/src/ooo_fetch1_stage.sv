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
//`include "predictor_pipeline_if.vh"
//`include "component_selection_defines.vh"
//`include "ooo_hazard_unit_if.vh"
//
//module ooo_fetch1_stage (
  //input logic CLK, nRST,halt,
  //ooo_fetch1_fetch2_if.fetch1 fetch1_fetch2_if,
  //predictor_pipeline_if.access predict_if,
  //ooo_hazard_unit_if.fetch1 hazard_if
//);
  //import rv32i_types_pkg::*;
//
  //parameter RESET_PC = 32'h80000000;
  //word_t current_pc, next_pc, pc4, npc;
  //logic prediction;
//
  ////next PC logic
//
  //always_ff @ (posedge CLK, negedge nRST) begin
    //if( ~nRST) begin
      //current_pc <= RESET_PC;
      //prediction <= 'h0;
    //end 
    //else begin
        //if (halt) begin
            //current_pc <= RESET_PC;
            //prediction <= 'h0;
        //end
        //else if ((hazard_if.pc_en && ~hazard_if.stall) || hazard_if.insert_priv_pc) 
        //begin
            //current_pc <= npc;
            //prediction <= predict_if.predict_taken;
        //end
    //end
  //end
 //
  ////FETCH1 FETCH 2 interface
  //assign fetch1_fetch2_if.pc = current_pc;
  //assign fetch1_fetch2_if.prediction = prediction;
  ////PREDICT_IF interface
  //assign predict_if.current_pc = current_pc;
  ////Next PC logic
  //assign pc4 = current_pc + 4;
  //assign npc = hazard_if.insert_priv_pc ? hazard_if.priv_pc : (hazard_if.intr_taken) ? current_pc: (hazard_if.csr_flush) ? (hazard_if.csr_pc +'h4): (hazard_if.ifence_flush) ? (hazard_if.ifence_pc +'h4): (hazard_if.npc_sel)? hazard_if. brj_addr : predict_if.predict_taken ? predict_if.target_addr : pc4;
//
//
//
//endmodule 
//
//
//
//
