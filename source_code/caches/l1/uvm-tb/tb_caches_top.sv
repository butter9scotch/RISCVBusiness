// package file
`include "rv32i_types_pkg.sv"

// design file
`include "l1_cache.sv"

// BFM file
`include "memory_bfm.sv"

// interface file
`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

// UVM test file
`include "raw_test.svh"

`timescale 1ns/1ps
// import uvm packages
import uvm_pkg::*;

module tb_caches_top ();
  logic clk;
  
  // generate clock
  initial begin
		clk = 0;
		forever #10 clk = !clk;
	end

  // instantiate the interface
  generic_bus_if cpu_bus_if();
  generic_bus_if l1_bus_if();
  l1_cache_wrapper_if cpu_cif(clk);

  //TODO: HOW DO WE GET THE CIF (FLUSH, CLEAR) SIGNALS FROM THE L1 TO THE L2/MEMORY
  l1_cache_wrapper_if mem_cif(clk);

  // instantiate the memory bus functional model
  memory_bfm bfm(
    .cif(cpu_cif.cache),
    .bus_if(l1_bus_if.generic_bus)
  );
  
  // instantiate the DUT
  // Data Cache Portmap
	l1_cache #(.CACHE_SIZE(2048),
	.BLOCK_SIZE(4),
	.ASSOC(2),
	.NONCACHE_START_ADDR(32'h8000_0000))
	l1 (
  .cif(cpu_cif.cache),
	.mem_gen_bus_if(l1_bus_if.cpu),
	.proc_gen_bus_if(cpu_bus_if.generic_bus));

  initial begin
    uvm_config_db#(virtual l1_cache_wrapper_if)::set( null, "", "cpu_cif", cpu_cif);
    uvm_config_db#(virtual l1_cache_wrapper_if)::set( null, "", "mem_cif", mem_cif);
    uvm_config_db#(virtual generic_bus_if)::set( null, "", "l1_bus_if", l1_bus_if);
    uvm_config_db#(virtual generic_bus_if)::set( null, "", "cpu_bus_if", cpu_bus_if);
    run_test();
  end
endmodule
