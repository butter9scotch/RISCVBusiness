/*
*   Copyright 2022 Purdue University
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
*   Filename:     cache_model.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  Abstracted software model of the caches
*/

`ifndef CACHE_MODEL_SVH
`define CACHE_MODEL_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

class cache_block;
    word_t words[word_t]; // key -> value :: addr -> data

    function bit size_check();
        if (words.size() >= `L1_BLOCK_SIZE)     return '0;
        else                                    return '1;
    endfunction: size_check

    function void insert(word_t addr, word_t data);
        if (!size_check()) begin
            `uvm_error("cache_block", $sformatf("Block overflow when attempting to insert item into cache: size %d:\ncache[%h]=%h", words.size(), addr, data));
        end
        if (words.exists(addr)) begin
            `uvm_error("cache_block", $sformatf("Attempted to insert item into cache that already exists:\ncache[%h]=%h", addr, data))
        end else begin
            words[addr] = data;
        end
    endfunction: insert

    function string sprint();
        string str = "[";
        foreach(words[w]) begin
            str = {str, $sformatf("%h, ", words[w])};
        end
        str = {str, "]\n"};
        return str;
    endfunction: sprint
endclass

class cache_model extends uvm_object;
    cache_block blocks[word_t]; // key -> value :: base addr -> block

    function new(string name = "cache_model");
        super.new(name);
    endfunction

    function word_t get_base_addr(word_t addr);
        word_t base = {addr[31:`L1_ADDR_IDX_END], {`L1_ADDR_IDX_END{1'b0}}};
        return base;
    endfunction: get_base_addr

    function void insert(word_t addr, word_t data);
        word_t base = get_base_addr(addr);

        if (exists(addr)) begin
            // cache block formation started
            `uvm_error(this.get_name(), $sformatf("Attempted to insert item from cache that already exists:\ncache[%h]=%h", addr, data))
        end else begin
            if (!blocks.exists(base)) begin
                blocks[base] = new();
            end
            blocks[base].insert(addr, data);
        end
    endfunction: insert

    function void remove(word_t addr, word_t data);
        word_t base = get_base_addr(addr);
        if (exists(addr)) begin
            blocks[base].words.delete(addr);
        end else begin
            `uvm_error(this.get_name(), $sformatf("Attempted to remove item from cache that DNE:\ncache[%h]=%h", addr, data))
        end
    endfunction: remove

    function void update(word_t addr, word_t data);
        word_t base = get_base_addr(addr);
        if (exists(addr)) begin
            blocks[base].words[addr] = data;
        end else begin
            `uvm_error(this.get_name(), $sformatf("Attempted to update item from cache that DNE:\ncache[%h]=%h", addr, data))
        end
    endfunction: update

    function bit exists(word_t addr);
        word_t base = get_base_addr(addr);
        return blocks.exists(base) && blocks[base].words.exists(addr);
    endfunction: exists

    function bit is_valid_block(word_t addr);
        word_t base = get_base_addr(addr);
        if (blocks.exists(base)) begin
            if (blocks[base].words.size() == 0) begin
                blocks.delete(base); // clean up evicted blocks
                return '1;
            end else begin
                return blocks[base].words.size() == `L1_BLOCK_SIZE; // ensure block is full
            end
        end else begin
            `uvm_info(this.get_name(), $sformatf("Unable to find block %h for requested addr: %h", base, addr), UVM_LOW);
            return '0;
        end
    endfunction: is_valid_block

    function string sprint();
        string str = "cache:\n";
        foreach(blocks[b]) begin
            str = {str, $sformatf("%h :: %s", b, blocks[b].sprint())};
        end
        return str;
    endfunction: sprint

endclass: cache_model

`endif