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
*   Filename:     separate_caches.sv
*
*   Created by:   Jacob R. Stevens
*   Email:        steven69@purdue.edu
*   Date Created: 11/08/2016
*   Description: Caches consisting of separate I$ and D$ 
*/

`include "generic_bus_if.vh"
`include "cache_control_if.vh"
`include "component_selection_defines.vh"

module separate_caches (
  input logic CLK, nRST, halt_flush, 
  output logic ihit, dhit,
  generic_bus_if.cpu icache_mem_gen_bus_if,
  generic_bus_if.cpu dcache_mem_gen_bus_if,
  generic_bus_if.generic_bus icache_proc_gen_bus_if,
  generic_bus_if.generic_bus dcache_proc_gen_bus_if,
  cache_control_if.caches cc_if
);

  // ICACHE CONFIG
  parameter ICACHE_SIZE                = 1024;
  parameter ICACHE_BLOCK_SIZE          = 2;
  parameter ICACHE_ASSOC               = 2; 
  parameter ICACHE_NONCACHE_START_ADDR = 32'h8FFFFFFF;

  // DCACHE CONFIG
  parameter DCACHE_SIZE                = 1024;
  parameter DCACHE_BLOCK_SIZE          = 2;
  parameter DCACHE_ASSOC               = 2; 
  parameter DCACHE_NONCACHE_START_ADDR = 32'h8FFFFFFF;

  generate
    case (DCACHE_TYPE)
      "l1" : begin
                        l1_cache #(.CACHE_SIZE(DCACHE_SIZE), .BLOCK_SIZE(DCACHE_BLOCK_SIZE), .ASSOC(DCACHE_ASSOC), .NONCACHE_START_ADDR(DCACHE_NONCACHE_START_ADDR)) dcache (
                          .CLK(CLK),
                          .nRST(nRST),
                          .clear(0),
                          .flush(halt_flush),
                          .hit(dhit),
                          .clear_done(cc_if.dclear_done),
                          .flush_done(cc_if.dflush_done),
                          .mem_gen_bus_if(dcache_mem_gen_bus_if),
                          .proc_gen_bus_if(dcache_proc_gen_bus_if)
                        );
      end
      "pass_through" : begin
                        pass_through_cache dcache(
                          .CLK(CLK),
                          .nRST(nRST),
                          .mem_gen_bus_if(dcache_mem_gen_bus_if),
                          .proc_gen_bus_if(dcache_proc_gen_bus_if)
                        );
                        assign cc_if.dclear_done = 1'b1;
                        assign cc_if.dflush_done = 1'b1;
      end
      "direct_mapped_tpf" : direct_mapped_tpf_cache dcache(
                          .CLK(CLK),
                          .nRST(nRST),
                          .mem_gen_bus_if(dcache_mem_gen_bus_if),
                          .proc_gen_bus_if(dcache_proc_gen_bus_if),
                          .flush(cc_if.dcache_flush),
                          .clear(cc_if.dcache_clear),
                          .flush_done(cc_if.dflush_done),
                          .clear_done(cc_if.dclear_done)
                        );
    endcase
  endgenerate

  generate
    case (ICACHE_TYPE)
      "l1" : begin
                        l1_cache #(.CACHE_SIZE(ICACHE_SIZE), .BLOCK_SIZE(ICACHE_BLOCK_SIZE), .ASSOC(ICACHE_ASSOC), .NONCACHE_START_ADDR(ICACHE_NONCACHE_START_ADDR)) icache (
                          .CLK(CLK),
                          .nRST(nRST),
                          .clear(0),
                          .flush(0),
                          .hit(ihit),
                          .clear_done(cc_if.iclear_done),
                          .flush_done(cc_if.iflush_done),
                          .mem_gen_bus_if(icache_mem_gen_bus_if),
                          .proc_gen_bus_if(icache_proc_gen_bus_if)
                        );
      end
      "pass_through" : begin
                        pass_through_cache icache(
                          .CLK(CLK),
                          .nRST(nRST),
                          .mem_gen_bus_if(icache_mem_gen_bus_if),
                          .proc_gen_bus_if(icache_proc_gen_bus_if)
                        );
                        assign cc_if.iclear_done = 1'b1;
                        assign cc_if.iflush_done = 1'b1;
      end
      "direct_mapped_tpf" : direct_mapped_tpf_cache icache(
                          .CLK(CLK),
                          .nRST(nRST),
                          .mem_gen_bus_if(icache_mem_gen_bus_if),
                          .proc_gen_bus_if(icache_proc_gen_bus_if),
                          .flush(cc_if.icache_flush),
                          .clear(cc_if.icache_clear),
                          .flush_done(cc_if.iflush_done),
                          .clear_done(cc_if.iclear_done)
                        );
    endcase
  endgenerate

endmodule
