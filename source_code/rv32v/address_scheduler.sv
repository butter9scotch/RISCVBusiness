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
*   Filename:     address_scheduler.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 10/15/2021
*   Description:  Schedule/arbitrate addresses
*/

`include "address_scheduler_if.vh"

module address_scheduler (
  input logic CLK, nRST,
  address_scheduler_if.address_scheduler asif
);

  import rv32i_types_pkg::*;

  logic misalign0, misalign1, daccess, done;

  typedef enum logic [2:0] {IDLE, LOAD0, LOAD1, STORE0, STORE1, EX} state_type;
  state_type state, next_state;

  assign daccess       = asif.load_ena | asif.store_ena;
  assign misalign0     = (asif.addr0[1:0] != 2'b00) & daccess;
  assign misalign1     = (asif.addr1[1:0] != 2'b00) & daccess;
  assign asif.arrived0 = state == LOAD0 & asif.dhit;
  assign asif.arrived1 = state == LOAD1 & asif.dhit;
  assign asif.byte_ena = (asif.eew_loadstore == WIDTH32 & ~asif.ls_idx) | (asif.sew == SEW32 & asif.ls_idx) ? 0: // choose csr sew for indexed load/store_ena, otherwise choose instr sew
                         (asif.eew_loadstore == WIDTH16 & ~asif.ls_idx) | (asif.sew == SEW16 & asif.ls_idx) ? 1:
                         2;
/*
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) done <= 0;
    else if (asif.arrived1 & asif.woffset1 == asif.vl) done <= 1;
    else if (daccess) done <= 0;
  end */

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) state <= IDLE;
    else state <= next_state;
  end

  always_comb begin
    next_state = state;
    case(state)
      IDLE:
      begin
        if (misalign0 & ~asif.segment_type) next_state = EX;
        else if (asif.load_ena) next_state = LOAD0;
        else if (asif.store_ena) next_state = STORE0;
      end 
      LOAD0:
      begin
        if (asif.dhit & misalign1 & ~asif.segment_type) next_state = EX;
        else if (asif.dhit) next_state = LOAD1;
      end 
      LOAD1:
      begin
        if (asif.dhit) next_state = IDLE;
      end 
      STORE0:
      begin
        if (asif.dhit & misalign1 & ~asif.segment_type) next_state = EX;
        else if (asif.dhit) next_state = STORE1;
      end 
      STORE1:
      begin
        if (asif.dhit) next_state = IDLE;
      end 
      EX:
      begin
        if (asif.returnex) next_state = IDLE;
      end 
    endcase
  end

  always_comb begin
    asif.final_addr = '0;
    asif.final_storedata = '0; 
    asif.wen = '0;
    asif.ren = '0;  
    asif.busy = 1; // TODO?  
    asif.exception = '0; 
    case(state)
      IDLE:
      begin
        if (~daccess) asif.busy = 0;
      end 
      LOAD0:
      begin
        asif.final_addr = asif.addr0;
        asif.ren = 1;
      end 
      LOAD1:
      begin
        asif.final_addr = asif.addr1;
        asif.ren = 1;
        asif.busy = ~asif.arrived1;
      end 
      STORE0:
      begin
        asif.final_addr = asif.addr0;
        asif.final_storedata = asif.storedata0; 
        asif.wen = 1;
      end 
      STORE1:
      begin
        asif.final_addr = asif.addr1;
        asif.final_storedata = asif.storedata1; 
        asif.wen = 1;
        asif.busy = ~asif.dhit;
      end 
      EX:
      begin
        asif.busy = 0;
        asif.exception = 1; 
      end 
    endcase
  end
endmodule
