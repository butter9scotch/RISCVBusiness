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
  input logic CLK, nRST,
  generic_bus_if.generic_bus scalar_gen_bus_if,
  generic_bus_if.generic_bus vector_gen_bus_if,
  generic_bus_if.cpu out_gen_bus_if
);
  // the only reason this works is because we expect the worst case 
  // is that vector ls followed by a scalar ls will come at the same cycle
  // and that the oldest instruction will always be the vector ls   

  typedef enum {
    IDLE,
    VEC_REQ, // servicing a vector memory request 
    INT_REQ  // servicing a scalar memory request 
  } req_state_t;

  req_state_t current_request, next_request;

  // intermediary signals to make it easier to understand the decision logic
  logic vector_request, scalar_request;
  assign vector_request = vector_gen_bus_if.ren | vector_gen_bus_if.wen;
  assign scalar_request = scalar_gen_bus_if.ren | scalar_gen_bus_if.wen;

  // current request register
  always_ff @(posedge CLK, negedge nRST) begin
    if(~nRST) begin
      current_request <= IDLE;
    end else begin
      current_request <= next_request;
    end
  end

  always_comb begin : NEXT_REQUEST_LOGIC
    next_request = current_request;
    casez(current_request)
      IDLE: begin
        // prioritize vector requests
        if (vector_request) begin
          next_request = VEC_REQ;
        end else if (scalar_request) begin
          next_request = INT_REQ;
        end else begin
          next_request = IDLE;
        end
      end
      VEC_REQ: begin
        // if the memory transaction is complete then go to idle
        // or the other request on the line
        if(~out_gen_bus_if.busy) begin
          if(scalar_request) begin
            next_request = INT_REQ;
          end else begin
            next_request = IDLE;
          end
        end
      end
      INT_REQ: begin
        // if the memory transaction is complete then go to idle
        // or the other request on the line
        if(~out_gen_bus_if.busy) begin
          if(vector_request) begin
            next_request = VEC_REQ;
          end else begin
            next_request = IDLE;
          end
        end
      end
    endcase
  end

  always_comb begin : OUTPUT_LOGIC
    // default ero the signals
    out_gen_bus_if.addr = '0;
    out_gen_bus_if.ren = '0;
    out_gen_bus_if.wen = '0;
    out_gen_bus_if.wdata = '0;
    out_gen_bus_if.byte_en = '0;
    scalar_gen_bus_if.rdata = '0;
    scalar_gen_bus_if.busy = 1;
    vector_gen_bus_if.rdata = '0;
    vector_gen_bus_if.busy = 1;
    // output logic based on next state to keep us in a single cycle hit
    casez(current_request)
      // connect the scalar loadstore unit
      INT_REQ : begin
        out_gen_bus_if.addr = scalar_gen_bus_if.addr;
        out_gen_bus_if.ren = scalar_gen_bus_if.ren;
        out_gen_bus_if.wen = scalar_gen_bus_if.wen;
        out_gen_bus_if.wdata = scalar_gen_bus_if.wdata;
        out_gen_bus_if.byte_en = scalar_gen_bus_if.byte_en;
        scalar_gen_bus_if.rdata = out_gen_bus_if.rdata;
        scalar_gen_bus_if.busy = out_gen_bus_if.busy;
      end
      // connect the vector loadstore unit
      VEC_REQ : begin
        out_gen_bus_if.addr = vector_gen_bus_if.addr;
        out_gen_bus_if.ren = vector_gen_bus_if.ren;
        out_gen_bus_if.wen = vector_gen_bus_if.wen;
        out_gen_bus_if.wdata = vector_gen_bus_if.wdata;
        out_gen_bus_if.byte_en = vector_gen_bus_if.byte_en;
        vector_gen_bus_if.rdata = out_gen_bus_if.rdata;
        vector_gen_bus_if.busy = out_gen_bus_if.busy;
      end
    endcase 
  end
endmodule

