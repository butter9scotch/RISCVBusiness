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
*   Filename:     l1_cache.sv
*
*   Created by:   Rufat Imanov
*   Email:        rimanov@purdue.edu
*   Date Created: 06/20/2021
*   Description:  L1 Cache to test Area of Module. The following are configurable:
*                   - Cache Size
*                   - Non-Cacheable start address
*                   - Block Size
*	            - ASSOC
*/

`include "generic_bus_if.vh"

module l1_cache
#(
    parameter CACHE_SIZE          = 1024; // must be power of 2, in bytes, max 2^32
    parameter BLOCK_SIZE          = 2; // must be power of 2, max 32
    parameter ASSOC               = 2; // max N_TOTAL_FRAMES
    parameter NONCACHE_START_ADDR = 32'h8000_0000;
)
(
    input logic CLK, nRST,
    input logic clear, flush,
    output logic clear_done, flush_done,
    generic_bus_if.cpu mem_gen_bus_if,
    generic_bus_if.generic_bus proc_gen_bus_if

);
    // TODO:
    // 1. Implement Byte Enable
    // 2. Implement Flush & Clear functunality
    // 3. Implement Cache Replacement Policy
    // 4. Direct Memory Access

    import rv32i_types_pkg::*;

    // local parameters
    localparam N_TOTAL_FRAMES     = CACHE_SIZE / (BLOCK_SIZE * WORD_SIZE / 8);
    localparam N_SETS             = N_TOTAL_FRAMES / ASSOC;
    localparam N_FRAMES           = $clog2(ASSOC);
    localparam N_SET_BITS         = $clog2(N_SETS);
    localparam N_BLOCK_BITS       = $clog2(BLOCK_SIZE);
    localparam N_TAG_BITS         = WORD_SIZE - N_SET_BITS - N_BLOCK_BITS - 2;
    localparam FRAME_SIZE         = WORD_SIZE * BLOCK_SIZE + N_TAG_BITS + 2; // in bits

    // cache frame type
    typedef struct packed {
        logic valid;
        logic dirty;
        logic [N_TAG_BITS - 1:0] tag;
        logic [WORD_SIZE - 1:0] data [BLOCK_SIZE - 1:0];
    } cache_frame;

    typedef struct packed {
        cache_frame frames[ASSOC - 1:0];
    } cache_sets;

    // FSM type
    typedef enum {
       IDLE, FETCH, WB, CLEAR_PREP, CLEAR_SET, CLEAR_FRAME
    } fsm_t;

    // Cache address decode type
    typedef struct packed {
        logic [N_TAG_BITS - 1:0] tag_bits;
        logic [N_SET_BITS - 1:0] set_bits;
        logic [N_BLOCK_BITS - 1:0] block_bits;
        logic [1:0] byte_bits;
    } decoded_addr_t;

    // Set Counter
    logic [31:0] set_num, next_set_num;
    logic en_set_ctr, clr_set_ctr;

    // Frame(way) Counter
    logic [31:0] frame_num, next_frame_num;
    logic en_frame_ctr, clr_frame_ctr;

    // Word Counter
    logic [4:0] word_num, next_word_num;
    logic en_word_ctr, clr_word_ctr;

    // Counter Finish flags
    logic finish_word, finish_frame, finish_set;

    // States
    fsm_t state, next_state;

    // cache blocks, indexing cache chooses a set
    cache_sets cache [N_SETS - 1:0];
    cache_sets next_cache [N_SETS - 1:0];

    // FF for counters
    always_ff @ (posedge CLK, negedge nRST) begin
        if(~nRST) begin
            set_num <= '0;
            frame_num <= '0;
            word_num <= '0;
        end
        else begin
            set_num <= next_set_num;
            frame_num <= next_frame_num;
            word_num <= next_word_num;
        end
    end // always_ff @

    // Comb. logic for counters
    always_comb begin
        next_set_num = set_num;
        next_frame_num = frame_num;
        next_word_num = word_num;

        if(clr_set_ctr) begin
            next_set_num = '0;
        end
        else if(en_set_ctr) begin
            next_set_num = set_num + 1'b1;
        end

        if(clr_frame_ctr) begin
            next_frame_num = '0;
        end
        else if(en_frame_ctr) begin
            next_frame_num = frame_num + 1'b1;
        end

        if(clr_word_ctr) begin
            next_word_num = '0;
        end
        else if(en_word_ctr) begin
            next_word_num = word_num + 1'b1;
        end
    end // always_comb

    // Comb. output logic for counter finish flags
    assign finish_set = (set_num == N_SETS) ? 1'b1 : 1'b0;
    assign finish_frame  = (frame_num == N_FRAMES) ? 1'b1 : 1'b0;
    assign finish_word 	= (word_num == BLOCK_SIZE) ? 1'b1 : 1'b0;

    // FF for cache
    always_ff @ (posedge CLK, negedge nRST) begin
        if(~nRST) begin
            for(int i = 0; i < N_SETS; i++) begin
                for(int j = 0; j < ASSOC; j++) begin
                    cache[i].frames[j].data <= '0;
                    cache[i].frames[j].tag  <= '0;
                    cache[i].frames[j].valid <= 1'b0;
                    cache[i].frames[j].dirty <= 1'b0;
                end
            end
	end
        else begin
            for(int i = 0; i < N_SETS; i++) begin
                for(int j = 0; j < ASSOC; j++) begin
                    cache[i].frames[j].data <= next_cache[i].frames[j].data;
                    cache[i].frames[j].tag  <= next_cache[i].frames[j].tag;
                    cache[i].frames[j].valid <= next_cache[i].frames[j].valid;
                    cache[i].frames[j].dirty <= next_cache[i].ways[j].dirty;
                end
            end
        end // else: !if(~nRST)
    end // always_ff @
    	
    // Decode incoming addr. to cache config. bits
    decoded_addr_t decoded_addr;
    assign decoded_addr = proc_gen_bus_if.addr;

    // Cache Hit
    logic hit, pass_through;
    logic [WORD_SIZE - 1:0] hit_data [BLOCK_SIZE - 1:0];
    logic [N_SET_FRAMES - 1:0] hit_idx;

    always_comb begin
        hit = 1'b0;
        pass_through = 1'b0;

        if(proc_gen_bus_if.addr >= NONCACHE_START_ADDR) begin
            pass_through = 1'b1;
        end
        else begin
            for(int i = 0; i < ASSOC; i++) begin
                if(cache[decoded_addr.set_bits].frames[i].tag == decoded_addr.tag_bits && cache[decoded_addr.set_bits].frames[i].valid) begin
                    hit = 1'b1;
                    hit_data = cache[decoded_addr.set_bits].frames[i].data;
                    hit_idx = i;
                end
            end
        end // else: !if(proc_gen_bus_if.addr >= NONCACHE_START_ADDR)
    end // always_comb

    // Here add logic for cache replacement policy
    logic [N_SET_FRAMES - 1:0] ridx;

    word_t read_addr, next_read_addr; // remember read addr. at IDLE to increment by 4 later when fetching
    always_ff @ (posedge CLK, negedge nRST) begin
	if(~nRST) begin
	    read_addr <= '0;
	end
	else begin
	    read_addr <= next_read_addr;
	end
    end

    // Comb. logic for outputs, maybe merging this comb. block with the one above
    // could be an optmization. Hopefully, synthesizer is smart to catch it.
    // for now leave it like this for readability.
    // Outputs: counter control signals, cache, signals to memory, signals to processor
    always_comb begin
        proc_gen_bus_if.busy  = 1'b1;
	mem_gen_bus_if.ren    = 1'b0;
	mem_gen_bus_if.wen    = 1'b0;
	en_set_ctr 	      = 1'b0;
	en_word_ctr 	      = 1'b0;
	en_frame_ctr 	      = 1'b0;
	clr_set_ctr 	      = 1'b0;
	clr_word_ctr 	      = 1'b0;
	clr_frame_ctr 	      = 1'b0;
	
        for(int i = 0; i < N_SETS; i++) begin
            for(int j = 0; j < ASSOC; j++) begin
                 next_cache[i].frames[j].data = cache[i].frames[j].data;
                 next_cache[i].frames[j].tag  = cache[i].frames[j].tag;
                 next_cache[i].frames[j].valid = cache[i].frames[j].valid;
                 next_cache[i].frames[j].dirty = cache[i].ways[j].dirty;
            end
        end

        casez(state)
            IDLE: begin
                if(proc_gen_bus_if.ren && hit) begin
                    proc_gen_bus_if.busy   = 1'b0;
                    proc_gen_bus_if.rdata  = hit_data;
                end
                else if(proc_gen_bus_if.wen && hit) begin
                    proc_gen_bus_if.busy 							    = 1'b0;
                    next_cache[decoded_addr.set_bits].frames[hit_idx].data[decoded_addr.block_bits]  = proc_gen_bus_if.wdata;
		    next_cache[decoded_addr.set_bits].frames[hit_idx].dirty 			    = 1'b1;
                end
		next_read_addr = decoded_addr;
            end // case: IDLE
            FETCH: begin
		mem_gen_bus_if.ren   = 1'b1;
		mem_gen_bus_if.addr  = read_addr;
		
		if(~proc_gen_bus_if.busy && finish_word) begin
		    clr_word_ctr 						   = 1'b1;
		    next_cache[decoded_addr.set_bits].frames[ridx].data[word_num]  = proc_gen_bus_if.rdata;
		    next_cache[decoded_addr.set_bits].frames[ridx].valid 	   = 1'b1;
		end
		else if(~proc_gen_bus_if.busy && ~finish_word) begin
		    en_word_ctr  = 1'b1;
		    next_read_addr = read_addr += 4;
		end
            end // case: FETCH
	    WB: begin
		mem_gen_bus_if.wen    = 1'b1;
		mem_gen_bus_if.addr   = read_addr;
		mem_gen_bus_if.wdata  = cache[decoded_addr.set_bits].frames[ridx].data[word_num];
		
		if(~proc_gen_bus_if.busy && finish_word) begin
		    clr_word_ctr 					  = 1'b1;
		    next_read_addr 					  = decoded_addr;
		    next_cache[decoded_addr.set_bits].frames[ridx].dirty  = 1'b0;
		end
		else if(~proc_gen_bus_if.busy && ~finish_word) begin
		    en_word_ctr     = 1'b1; // use word number to assign mem. addr.
		    next_read_addr  = read_addr += 4;
		end
	    end // case: WB
        endcase // casez (state)
    end // always_comb

    // Comb. logic for next state
    always_comb begin
	next_state = state;
	casez(state)
	    IDLE: begin
		if((proc_gen_bus_if.ren || proc_gen_bus_if.wen) && ~hit && cache[decoded_addr.set_bits].frames[ridx].dirty) begin
		    next_state 	= WB;
		end
		else if((proc_gen_bus_if.ren || proc_gen_bus_if.wen) && ~hit && ~cache[decoded_addr.set_bits].frames[ridx].dirty) begin
		    next_state 	= FETCH;
		end
	    end
	    FETCH: begin
		if(~proc_gen_bus_if.busy && finish_word) begin
		    next_state 	= IDLE;
		end
	    end
	    WB: begin
		if(~proc_gen_bus_if.busy && finish_word) begin
		    next_state 	= FETCH;
		end
	    end
	endcase // casez (state)
    end // always_comb
    
endmodule // l1_cache

