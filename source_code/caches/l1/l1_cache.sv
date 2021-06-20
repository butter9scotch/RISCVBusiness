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
*   Filename:     direct_mapped_tpf_cache.sv
*
*   Created by:   Rufat Imanov
*   Email:        rimanov@purdue.edu
*   Date Created: 06/20/2021
*   Description:  L1 Cache to test Area of Module. The following are configurable:
*                   - Cache Size
*                   - Non-Cacheable start address
*                   - Block Size
*	                - ASSOC (not yet)
*/

`include "generic_bus_if.vh"

module l1_cache #(
    parameter CACHE_SIZE          = 1024, // must be power of 2, in bytes
    parameter BLOCK_SIZE          = 2, // must be power of 2
    // parameter ASSOC               = 8,
    parameter NONCACHE_START_ADDR = 32'h8000_0000

)(
    input logic CLK, nRST,
    input logic clear, flush,
    output logic clear_done, flush_done,
    generic_bus_if.cpu mem_gen_bus_if,
    generic_bus_if.generic_bus proc_gen_bus_if
);

    import rv32i_types_pkg::*;

    // local parameters
    localparam N_FRAMES   = CACHE_SIZE / (BLOCK_SIZE * WORD_SIZE / 8);
    localparam N_SETS     = N_INDICES / 8; // N_INDICES / ASSOC;
    localparam SET_BITS   = $clog2(N_SETS);
    localparam BLOCK_BITS = $clog2(BLOCK_SIZE);
    localparam TAG_BITS   = WORD_SIZE - SET_BITS - BLOCK_BITS - 2;
    localparam FRAME_SIZE = WORD_SIZE * BLOCK_SIZE + TAG_BITS + 2; // in bits
    
    // cache frame type
    typedef struct packed {
        logic valid,
        logic dirty,
        logic [TAG_BITS - 1 : 0] tag;
        logic [WORD_SIZE - 1 : 0] data [BLOCK_SIZE - 1 : 0];
    } cache_frame;
    
    typedef struct packed {
        cache_frame ways[7 : 0]; // [ASSOC - 1 : 0];
     } cache_sets;
    
    // cache FF blocks
    cache_sets cache [N_SETS - 1 : 0]; 
    cache_sets next_cache [N_SETS - 1 : 0];
    always_ff @ (posedge CLK, negedge nRST) begin
        if(~nRST) begin
            for(integer i = 0; i < N_SETS; i++) begin
                for(integer j = 0; j < 8; j++) begin // j < ASSOC; j++) begin
                    cache[i].ways[j].data <= '0;
                    cache[i].ways[j].tag  <= '0;
                    cache[i].ways[j].valid <= 1'b0;
                    cache[i].ways[j].dirty <= 1'b0;
                end
            end
        else begin
            for(integer i = 0; i < N_SETS; i++) begin
                for(integer j = 0; j < 8; j++) begin // j < ASSOC; j++) begin
                    cache[i].ways[j].data <= next_cache[i].ways[j].data;
                    cache[i].ways[j].tag  <= next_cache[i].ways[j].tag;
                    cache[i].ways[j].valid <= next_cache[i].ways[j].valid;
                    cache[i].ways[j].dirty <= next_cache[i].ways[j].dirty;
                end
            end
        end 
    end
    
    always_comb begin
    
    
    
    end


endmodule
