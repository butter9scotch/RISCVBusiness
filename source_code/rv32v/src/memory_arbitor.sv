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
*   Filename:     memory_arbitor.sv
*
*   Created by:   Nicholas Gildenhuys
*   Email:        ngildenh@purdue.edu
*   Date Created: 02/02/2022
*   Description:  This is a module to arbitrate control over the cache bus
*                 between the base integer core and the vector extension
*/

`include "generic_bus_if.vh"
`include "rv32v_memory_arbitor_if.vh"
module memory_arbitor(
  rv32v_memory_arbitor_if.arbitor arb_if,
  generic_bus_if.generic_bus scalar_gen_bus_if,
  generic_bus_if.generic_bus vector_gen_bus_if,
  generic_bus_if.cpu out_gen_bus_if
);
  parameter NUM_CB_ENTRY = 16;

  let MSB(sig) = sig[$left(sig)];

  typedef enum {
    IDLE,
    VEC_REQ,
    INT_REQ
  } req_state_t;

  req_state_t current_request;

  logic [$clog2(NUM_CB_ENTRY)-1:0] vector_tail_dist;
  logic [$clog2(NUM_CB_ENTRY)-1:0] scalar_tail_dist;

  // find the distance to the tail pointer
  assign vector_tail_dist = arb_if.vector_cb_index - arb_if.cb_tail_index;
  assign scalar_tail_dist = arb_if.scalar_cb_index - arb_if.cb_tail_index;


  always_comb begin : DECISION_LOGIC
    current_request = IDLE;
    out_gen_bus_if.addr = '0;
    out_gen_bus_if.ren = '0;
    out_gen_bus_if.wen = '0;
    out_gen_bus_if.wdata = '0;
    out_gen_bus_if.byte_en = '0;
    scalar_gen_bus_if.rdata = '0;
    scalar_gen_bus_if.busy = 1;
    vector_gen_bus_if.rdata = '0;
    vector_gen_bus_if.busy = 1;
    // if the tail pointer is larger than the head pointer and both entries are
    // larger than the tail pointer take the larger unsigned integer
    if (~vector_gen_bus_if.wen & ~vector_gen_bus_if.ren) begin
      current_request = INT_REQ;
    end else if (~scalar_gen_bus_if.wen & ~scalar_gen_bus_if.ren) begin
      current_request = VEC_REQ;
    end else if (vector_tail_dist[$left(vector_tail_dist)] == scalar_tail_dist[$left(scalar_tail_dist)] & 1) begin
      if ($unsigned(vector_tail_dist) > $unsigned(scalar_tail_dist)) begin
        current_request = INT_REQ;
      end else if ($unsigned(vector_tail_dist) <= $unsigned(scalar_tail_dist)) begin
        current_request = VEC_REQ;
      end
    // else take the smaller unsigned integer
    end else begin
      if ($unsigned(vector_tail_dist) > $unsigned(scalar_tail_dist)) begin
        current_request = VEC_REQ;
      end else if ($unsigned(vector_tail_dist) <= $unsigned(scalar_tail_dist)) begin
        current_request = INT_REQ;
      end
    end
    // output logic
    casez(current_request)
      INT_REQ : begin
        out_gen_bus_if.addr = scalar_gen_bus_if.addr;
        out_gen_bus_if.ren = scalar_gen_bus_if.ren;
        out_gen_bus_if.wen = scalar_gen_bus_if.wen;
        out_gen_bus_if.wdata = scalar_gen_bus_if.wdata;
        out_gen_bus_if.byte_en = scalar_gen_bus_if.byte_en;
        scalar_gen_bus_if.rdata = out_gen_bus_if.rdata;
        scalar_gen_bus_if.busy = out_gen_bus_if.busy;
      end
      VEC_REQ : begin
        out_gen_bus_if.addr = vector_gen_bus_if.addr;
        out_gen_bus_if.ren = vector_gen_bus_if.ren;
        out_gen_bus_if.wen = vector_gen_bus_if.wen;
        out_gen_bus_if.wdata = vector_gen_bus_if.wdata;
        out_gen_bus_if.byte_en = vector_gen_bus_if.byte_en;
        vector_gen_bus_if.rdata = out_gen_bus_if.rdata;
        vector_gen_bus_if.busy = out_gen_bus_if.busy;
      end
      default : begin
        out_gen_bus_if.addr = '0;
        out_gen_bus_if.ren = '0;
        out_gen_bus_if.wen = '0;
        out_gen_bus_if.wdata = '0;
        out_gen_bus_if.byte_en = '0;
        scalar_gen_bus_if.rdata = '0;
        scalar_gen_bus_if.busy = 1;
        vector_gen_bus_if.rdata = '0;
        vector_gen_bus_if.busy = 1;
      end
    endcase 
  end
endmodule

