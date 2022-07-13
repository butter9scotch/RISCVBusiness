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

module sram_wrapper #(
    parameter ASSOC = 1, // 1 or 2 so far
    // parameter N_FRAME_BITS = 1 // $clog2(ASSOC)
    parameter N_SET = 512, // TODO: is it necessary?
    // parameter N_SET_BITS = 9, // $clog2(N_SETS)
    parameter BLOCK_SIZE = 2, // must be power of 2, max 8 (in 16 bit word_t?)
    // parameter N_TAG_BITS = 4, // 16 - 9 - 1 - 2
)
(
    input logic CLK, nRST,
    input logic clear, flush, // TODO: not planned yet

    input logic [N_SET_BITS - 1:0] set_bits,
    input logic [N_FRAME_BITS - 1:0] frame_bits,
    input logic chip_select,
    input logic write_enable,
    input logic output_enable,

    input word_t [BLOCK_SIZE - 1:0] input_data,

    output word_t [BLOCK_SIZE - 1:0] output_data,
);

// model sync SRAM

word_t [BLOCK_SIZE - 1:0] sram_data [N_SET][ASSOC];

always_ff@(posedge CLK) begin
    if(chip_select) begin
        if(write_enable && ~output_enable) begin
            sram_data[set_bits][frame_bits] = input_data;
        end else if (output_enable && ~write_enable) begin
            output_data = sram_data[set_bits][frame_bits];
        end
    end
end

endmodule