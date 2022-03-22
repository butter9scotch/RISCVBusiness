`ifndef CACHE_ENV_CONFIG
`define CACHE_ENV_CONFIG

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

class cache_env_config extends uvm_object;
    int mem_timeout;
    int mem_latency;
    int mmio_latency;

    rand logic[15:0] mem_tag; // used by mem bfm and bus predictors for non-initialized memory
    rand logic[15:0] mmio_tag; // used by mem bfm and bus predictors for memory mapped io response to reads

    `uvm_object_utils_begin(cache_env_config)
       `uvm_field_int(mem_timeout, UVM_ALL_ON)
       `uvm_field_int(mem_latency, UVM_ALL_ON)
       `uvm_field_int(mmio_latency, UVM_ALL_ON)
       `uvm_field_int(mem_tag, UVM_ALL_ON)
       `uvm_field_int(mmio_tag, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "cache_env_config");
        super.new(name);
        if (!uvm_config_db#(uvm_bitstream_t)::get(null,"","mem_timeout",mem_timeout)) begin
            `uvm_fatal("mem_timeout", "No parameter passed in from command line with uvm_set_config_int");
        end

        if (!uvm_config_db#(uvm_bitstream_t)::get(null,"","mem_latency",mem_latency)) begin
            `uvm_fatal("mem_latency", "No parameter passed in from command line with uvm_set_config_int");
        end

        if (!uvm_config_db#(uvm_bitstream_t)::get(null,"","mmio_latency",mmio_latency)) begin
            `uvm_fatal("mmio_latency", "No parameter passed in from command line with uvm_set_config_int");
        end
    endfunction

    function void post_randomize();
        `uvm_info(this.get_name(), $sformatf("env_config params:\n%s", this.sprint()), UVM_LOW)
    endfunction: post_randomize

endclass: cache_env_config

`endif