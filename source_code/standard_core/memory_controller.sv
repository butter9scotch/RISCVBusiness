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
*   Filename:     memory_controller.sv
*   
*   Created by:   John Skubic
*   Modified by:  Chuan Yean Tan
*   Email:        jskubic@purdue.edu , tan56@purdue.edu
*   Date Created: 09/12/2016
*   Description:  Memory controller and arbitration between instruction
*                 and data accesses
*/

`include "generic_bus_if.vh"
`include "component_selection_defines.vh"

module memory_controller (
  input logic CLK, nRST,
  generic_bus_if.generic_bus d_gen_bus_if,
  generic_bus_if.generic_bus i_gen_bus_if,
  generic_bus_if.cpu out_gen_bus_if
);

  /* State Declaration */ 
  typedef enum { 
                    IDLE, 
                    INSTR_REQ ,
                    INSTR_WAIT, 
                    DATA_REQ ,
                    DATA_INSTR_REQ ,
                    DATA_WAIT
                    } state_t; 

  state_t current_state, next_state;

  /* Internal Signals */
  logic [31:0] wdata, rdata; 

  always_ff @ (posedge CLK, negedge nRST) 
  begin 
    if (nRST == 0) 
      current_state <= IDLE; 
    else 
      current_state <= next_state; 
  end 

  /* State Transition Logic */ 
  always_comb 
  begin 
    case(current_state) 
      IDLE: begin
        if(d_gen_bus_if.ren || d_gen_bus_if.wen) 
          next_state = DATA_REQ; 
        else if(i_gen_bus_if.ren) 
          next_state = INSTR_REQ; 
        else 
          next_state = IDLE; 
      end 

      INSTR_REQ: begin 
        if( (d_gen_bus_if.ren || d_gen_bus_if.wen) && !out_gen_bus_if.busy) 
          next_state = DATA_WAIT;
        else if ( !out_gen_bus_if.busy ) 
        begin 
          next_state = IDLE; 
        end 
        else 
          next_state = INSTR_WAIT; 
      end

      DATA_REQ: begin 
        next_state = DATA_INSTR_REQ; 
      end

      DATA_INSTR_REQ: begin 
        if( out_gen_bus_if.busy == 1'b0 ) 
          next_state = INSTR_WAIT; 
        else 
          next_state = DATA_INSTR_REQ; 
      end 

      INSTR_WAIT: begin 
        if ( out_gen_bus_if.busy == 1'b0 ) 
            next_state = IDLE; 
        else 
            next_state = INSTR_WAIT; 
      end 

      DATA_WAIT: begin 
        if ( out_gen_bus_if.busy == 1'b0 ) 
            next_state = IDLE; 
        else 
            next_state = INSTR_WAIT; 
      end 

      default: next_state = IDLE; 
    endcase 
  end 

  /* State Output Logic */ 
  always_comb 
  begin 
    case(current_state) 
      IDLE: begin 
        out_gen_bus_if.wen      = 0;  
        out_gen_bus_if.ren      = 0;  
        out_gen_bus_if.addr     = 0;  
        out_gen_bus_if.byte_en  = d_gen_bus_if.byte_en;
        d_gen_bus_if.busy       = 1'b1;
        i_gen_bus_if.busy       = 1'b1;
      end

      //-- INSTRUCTION REQUEST --// 
      INSTR_REQ: begin 
        out_gen_bus_if.wen      = i_gen_bus_if.wen;
        out_gen_bus_if.ren      = i_gen_bus_if.ren;
        out_gen_bus_if.addr     = i_gen_bus_if.addr;
        out_gen_bus_if.byte_en  = i_gen_bus_if.byte_en;
        d_gen_bus_if.busy       = 1'b1;
        i_gen_bus_if.busy       = out_gen_bus_if.busy;
      end 
      INSTR_WAIT: begin 
        out_gen_bus_if.wen      = 0;  
        out_gen_bus_if.ren      = 0;  
        out_gen_bus_if.addr     = 0;  
        out_gen_bus_if.byte_en  = i_gen_bus_if.byte_en;
        d_gen_bus_if.busy       = 1'b1;
        i_gen_bus_if.busy       = out_gen_bus_if.busy;
      end 

      //-- DATA REQUEST --//
      DATA_REQ: begin 
        out_gen_bus_if.wen      = d_gen_bus_if.wen;
        out_gen_bus_if.ren      = d_gen_bus_if.ren;
        out_gen_bus_if.addr     = d_gen_bus_if.addr;
        out_gen_bus_if.byte_en  = d_gen_bus_if.byte_en;
        d_gen_bus_if.busy       = out_gen_bus_if.busy;
        i_gen_bus_if.busy       = 1'b1;
      end 
      DATA_INSTR_REQ: begin 
        out_gen_bus_if.wen      = i_gen_bus_if.wen;
        out_gen_bus_if.ren      = i_gen_bus_if.ren;
        out_gen_bus_if.addr     = i_gen_bus_if.addr;
        out_gen_bus_if.byte_en  = i_gen_bus_if.byte_en;
        d_gen_bus_if.busy       = out_gen_bus_if.busy;
        i_gen_bus_if.busy       = 1'b1;
      end 
      DATA_WAIT: begin 
        out_gen_bus_if.wen      = d_gen_bus_if.wen;
        out_gen_bus_if.ren      = d_gen_bus_if.ren;
        out_gen_bus_if.addr     = d_gen_bus_if.addr;
        out_gen_bus_if.byte_en  = d_gen_bus_if.byte_en;
        d_gen_bus_if.busy       = 1'b1;
        i_gen_bus_if.busy       = out_gen_bus_if.busy;
      end 
    endcase 
  end

  generate
    if(BUS_ENDIANNESS == "big")
    begin
      assign wdata  = d_gen_bus_if.wdata;
      assign rdata  = out_gen_bus_if.rdata;
    end else if (BUS_ENDIANNESS ==  "little")
    begin
      logic [31:0] little_endian_wdata, little_endian_rdata;
      endian_swapper wswap(d_gen_bus_if.wdata, little_endian_wdata);
      endian_swapper rswap(out_gen_bus_if.rdata, little_endian_rdata);
      assign wdata  = little_endian_wdata;
      assign rdata  = little_endian_rdata;
    end else
    begin
    //TODO ERROR
    end
  endgenerate
 
  /*  align the byte enable with the data being selected 
      based on the byte addressing */
  always_comb begin
    casez (d_gen_bus_if.byte_en)
      4'b1111, 4'b0011, 4'b0001 : out_gen_bus_if.wdata = wdata;      
      4'b0010                   : out_gen_bus_if.wdata = wdata << 8;
      4'b0100, 4'b1100          : out_gen_bus_if.wdata = wdata << 16;
      4'b1000                   : out_gen_bus_if.wdata = wdata << 24;
      default                   : out_gen_bus_if.wdata = wdata;
    endcase
  end

  assign d_gen_bus_if.rdata   = rdata;
  assign i_gen_bus_if.rdata   = rdata;
endmodule
