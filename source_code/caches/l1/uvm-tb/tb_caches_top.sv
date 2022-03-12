// package file
`include "rv32i_types_pkg.sv"

// design file
`include "l1_cache.sv"

// Interface checker file
`include "interface_checker.svh"

// interface file
`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

// UVM test file
`include "nominal_test.svh"
`include "evict_test.svh"
`include "mmio_test.svh"
`include "random_test.svh"

// Device Parameter Build Constants
`include "dut_params.svh"

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
  
  // instantiate the DUT
  // Data Cache Portmap
	l1_cache #(.CACHE_SIZE(`L1_CACHE_SIZE),
	.BLOCK_SIZE(`L1_BLOCK_SIZE),
	.ASSOC(`L1_ASSOC),
	.NONCACHE_START_ADDR(`NONCACHE_START_ADDR))
	l1 (
  .CLK(clk),
  .nRST(cpu_cif.nRST),
  .clear(cpu_cif.clear),
  .flush(cpu_cif.flush),
  .clear_done(cpu_cif.clear_done),
  .flush_done(cpu_cif.flush_done),
	.mem_gen_bus_if(l1_bus_if.cpu),
	.proc_gen_bus_if(cpu_bus_if.generic_bus));

  interface_checker if_check(
    .cif(cpu_cif.cache),
	  .cpu_if(cpu_bus_if.generic_bus),
    .mem_if(l1_bus_if.generic_bus)
  );  

  initial begin
    uvm_config_db#(virtual l1_cache_wrapper_if)::set( null, "", "cpu_cif", cpu_cif);
    uvm_config_db#(virtual l1_cache_wrapper_if)::set( null, "", "mem_cif", mem_cif);
    uvm_config_db#(virtual generic_bus_if)::set( null, "", "l1_bus_if", l1_bus_if);
    uvm_config_db#(virtual generic_bus_if)::set( null, "", "cpu_bus_if", cpu_bus_if);
    run_test();
  end
endmodule
