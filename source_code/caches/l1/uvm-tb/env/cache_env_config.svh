`ifndef CACHE_ENV_CONFIG
`define CACHE_ENV_CONFIG

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

class cache_env_config extends uvm_object;
    // TODO: WHAT CONFIGURATION INFO SHOULD WE ADD HERE?
    function new(string name = "cache_env_config");
        super.new(name);
    endfunction

endclass: cache_env_config

`endif