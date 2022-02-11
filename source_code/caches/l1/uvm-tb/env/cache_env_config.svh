`ifndef CACHE_ENV_CONFIG
`define CACHE_ENV_CONFIG

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`define CONFIG_NONCACHE_START_ADDR 32'h8000_0000

class cache_env_config extends uvm_object;
    function new(string name = "cache_env_config");
        super.new(name);
    endfunction

endclass: cache_env_config

`endif