// package file
`include "rv32i_types_pkg.sv"

// design file
`include "l1_cache.sv"

// interface file
`include "generic_bus_if.vh"
`include "l1_cache_wrapper_if.svh"

// UVM test file
`include "test.svh"

`timescale 1ns/1ps
// import uvm packages
import uvm_pkg::*;

module tb_l1_cache ();
  logic clk;
  
  // generate clock
  initial begin
		clk = 0;
		forever #10 clk = !clk;
	end

  // instantiate the interface
  generic_bus_if cpu_bus_if();
  generic_bus_if l1_bus_if();
  l1_cache_wrapper_if cif(clk);
  
  // instantiate the DUT
  // Data Cache Portmap
	l1_cache #(.CACHE_SIZE(2048),
	.BLOCK_SIZE(4),
	.ASSOC(2),
	.NONCACHE_START_ADDR(32'h8000_0000))
	DATA_CACHE (
  .cif(cif.cache),
	.mem_gen_bus_if(l1_bus_if.cpu),
	.proc_gen_bus_if(cpu_bus_if.generic_bus));

	// Instruction Cache Portmap
	l1_cache #(.CACHE_SIZE(1024),
	.BLOCK_SIZE(2),
	.ASSOC(1),
	.NONCACHE_START_ADDR(32'h8000_0000))
	INST_CACHE (
	.cif(cif.cache),
	.mem_gen_bus_if(l1_bus_if.cpu),
	.proc_gen_bus_if(cpu_bus_if.generic_bus));

  initial begin
    uvm_config_db#(virtual l1_cache_wrapper_if)::set( null, "", "cif", cif);
    uvm_config_db#(virtual generic_bus_if)::set( null, "", "l1_bus_if", l1_bus_if);
    uvm_config_db#(virtual generic_bus_if)::set( null, "", "cpu_bus_if", cpu_bus_if);
    run_test();
  end
endmodule
