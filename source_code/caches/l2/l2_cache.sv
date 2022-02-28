/*
*   Copyright 2016 Purdue University
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*       http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless `quired by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*
*
*   Filename:     l2_cache.sv
*
*   Created by:   Aedan Frazier, Dhruv Gupta, Rufat Imanov
*   Email:        frazie35@purdue.edu, gupta479@purdue.edu
*   Date Created: 02/28/2022
*   Description:  L2 Cache. The following are configurable:
*                   - Cache Size
*                   - Non-Cacheable start address
*                   - Block Size | max 4
*	                - ASSOC | either 2 or 4
*/

`include "generic_bus_if.vh"

module l2_cache #(
    parameter CACHE_SIZE          = 4096, // in bits
    parameter BLOCK_SIZE          = 4, // in words (must be power of 2)
    parameter ASSOC               = 4, // 2 or 4 so far
    parameter NONCACHE_START_ADDR = 32'h8000_0000
)
(
    input logic CLK, nRST,
    input logic clear, flush,
    output logic clear_done, flush_done,
    generic_bus_if.cpu mem_gen_bus_if,
    generic_bus_if.generic_bus proc_gen_bus_if

);
    import rv32i_types_pkg::*;

    // local parameters
    localparam N_TOTAL_FRAMES     = CACHE_SIZE / (BLOCK_SIZE * WORD_SIZE / 8); // Default 32
    localparam N_SETS             = N_TOTAL_FRAMES / ASSOC; //Default 8
    localparam N_FRAME_BITS       = $clog2(ASSOC); 
    localparam N_SET_BITS         = $clog2(N_SETS);
    localparam N_BLOCK_BITS       = $clog2(BLOCK_SIZE);
    localparam N_TAG_BITS         = WORD_SIZE - N_SET_BITS - N_BLOCK_BITS - 2;
    localparam FRAME_SIZE         = WORD_SIZE * BLOCK_SIZE + N_TAG_BITS + 2; // in bits

    // cache frame type
    typedef struct packed {
        logic valid;
        logic dirty;
        logic [N_TAG_BITS - 1:0] tag;
        word_t [BLOCK_SIZE - 1:0] data;
    } cache_frame;

    typedef struct packed {
        cache_frame [ASSOC - 1:0] frames;
    } cache_sets;

    // FSM type
    typedef enum { 
       IDLE, FETCH, WB, FLUSH_CACHE, FLUSH_SET, FLUSH_FRAME //NEED TO UPDATE
    } fsm_t;
    
    // Cache address decode type
    typedef struct packed {
        logic [N_TAG_BITS - 1:0] tag_bits;
        logic [N_SET_BITS - 1:0] index_bits;
        logic [N_BLOCK_BITS - 1:0] block_bits;
        logic [1:0] byte_bits;
    } decoded_addr_t;

    //Declarations
    decoded_addr_t decoded_addr;
    assign decoded_addr = proc_gen_bus_if.addr;

    fsm_t state, nextstate;

    // cache blocks, indexing cache chooses a set
    cache_sets cache [N_SETS - 1:0];
    cache_sets nextcache [N_SETS - 1:0];

    // Cache Hit signals
    logic hit, pass_through;
    word_t [BLOCK_SIZE - 1:0] hit_data;
    logic [(ASSOC/2)-1] hit_idx;

    //Sequential Logic
    always_ff @(posedge CLK, negedge nRST)begin
        if(~nRST)begin
            state <= IDLE; //Cache state machine reset state
            cache <= '0; // Cache frame reset
            
        end
        else begin
            state <= nextstate; //update FSM
            cache <= nextcache; // update cache frames
        end
    end// always_ff

    
    always_comb begin // output always_comb
        hit = 1'b0;
        pass_through = 1'b0;

        if(proc_gen_bus_if.addr >= NONCACHE_START_ADDR) begin //Passthrough
            pass_through = 1'b1;
        end 
        else begin 
            for(int i = 0; i < ASSOC; i++)begin
                if((cache[decoded_addr.index_bits].frames[i].tag == decoded_addr.tag_bits) && cache[decoded_addr.index_bits].valid)begin //hit
                        hit = 1'b1;
                end
            end
        end
    end // output always_comb end

    always_comb begin // Cache update logic
        nextcache = cache;
    end //end cache update logic

    always_comb begin // state machine comb
    nextstate = state;
    casez(state)
        IDLE: begin
            nextstate = IDLE;
        end 
    end // end state machine alqways_comb


endmodule // l2_cache

