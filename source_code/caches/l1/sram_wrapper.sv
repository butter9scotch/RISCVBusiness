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
*   Filename:     sram_wrapper.sv
*
*   Created by:   Yiyang Shui
*   Email:        shuiy@purdue.edu
*   Date Created: 06/29/2022
*   Description:  Wrapper file for implementing SRAM in L1 cache
*                 also for implementing flip-flop for verification purpose
*                 currently only store data bits
*/

`include "generic_bus_if.vh"
//import rv32i_types_pkg::word_t;

module sram_wrapper #(
    parameter ASSOC = 1, // 1 or 2 so far
    parameter N_FRAME_BITS = 1, // $clog2(ASSOC)
    parameter N_SETS = 512, // TODO: is it necessary?
    parameter N_SET_BITS = 6, // $clog2(N_SETS)
    parameter BLOCK_SIZE = 2, // must be power of 2, max 8 (in 16 bit word_t?)
    parameter N_BLOCK_BITS = 1
    // parameter N_TAG_BITS = 4, // 16 - 9 - 1 - 2
)
(
    input logic CLK, nRST,

    input logic [N_SET_BITS - 1:0] set_bits,
    input logic [N_FRAME_BITS - 1:0] frame_bits,
    input logic chip_select,
    input logic write_enable,
    input logic output_enable,

    input logic [N_BLOCK_BITS - 1:0] word_num, // due to limit of input data width in l1_cache.sv
    input logic [31:0] input_data,

    output logic [BLOCK_SIZE - 1:0][31:0] output_data,
    output logic busy
);

    typedef logic [32-1:0] word_t;

    import rv32i_types_pkg::*;

// model sync SRAM

word_t [BLOCK_SIZE - 1:0] sram_data [N_SETS][ASSOC];
word_t [BLOCK_SIZE - 1:0] output_data_pre;

always_ff@(posedge CLK) begin
    if(chip_select) begin
        if(write_enable && ~output_enable) begin
            sram_data[set_bits][frame_bits][word_num] <= input_data;
            output_data_pre <= '0;
        end else if (output_enable && ~write_enable) begin
            output_data_pre <= sram_data[set_bits][frame_bits];
        end else begin
            output_data_pre <= '0;
        end
    end else begin
        output_data_pre <= '0;
    end
end

assign output_data = busy ? '0 : output_data_pre;

// busy logic: indicate the 1-cycle read & write of sync SRAM
logic next_busy;
always_ff@(posedge CLK, posedge nRST) begin
    if(~nRST) begin
        busy <= 1'b1;
    end else begin
        busy <= next_busy;
    end
end

always_comb begin   // requires CLK_SRAM is twice as fast as CLK (two-cycle read)
    next_busy = 1'd1;

    if((write_enable || output_enable) && busy) 
        next_busy = 1'b0;
    else if((write_enable || output_enable) && ~busy)
        next_busy = 1'b1;
end

endmodule