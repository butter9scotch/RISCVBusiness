`ifndef L2_BFM_SVH
`define L2_BFM_SVH

`include "bus_ctrl_if.sv"
`include "dut_params.svh"

class l2_bfm;

  logic [`BLOCK_SIZE_WORDS-1:0][31:0] words;
  rand logic [15:0] tag;

  function logic [31:0] read(logic [31:0] addr);
    return {tag, addr[15:0]};
  endfunction

  function void write(logic [31:0] addr, logic [31:0] data);
    words[addr] = data;
  endfunction

endclass

`endif