`ifndef CACHE_MODEL_SVH
`define CACHE_MODEL_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

class cache_model extends uvm_object;
    word_t cache[word_t];

    function new(string name = "cache_model");
        super.new(name);
    endfunction

    function void insert(word_t addr, word_t data);
        if (cache.exists(addr)) begin
            `uvm_error(this.get_name(), $sformatf("Attempted to insert item from cache that already exists:\ncache[%h]=%h", addr, data))
        end else begin
            cache[addr] = data;
        end
    endfunction: insert

    function void remove(word_t addr, word_t data);
        if (cache.exists(addr)) begin
            cache.delete(addr);
        end else begin
            `uvm_error(this.get_name(), $sformatf("Attempted to remove item from cache that DNE:\ncache[%h]=%h", addr, data))
        end
    endfunction: remove

    function void update(word_t addr, word_t data);
        if (cache.exists(addr)) begin
            cache[addr] = data;
        end else begin
            `uvm_error(this.get_name(), $sformatf("Attempted to update item from cache that DNE:\ncache[%h]=%h", addr, data))
        end
    endfunction: update

    function bit exists(word_t addr);
        return cache.exists(addr);
    endfunction: exists


endclass: cache_model

`endif