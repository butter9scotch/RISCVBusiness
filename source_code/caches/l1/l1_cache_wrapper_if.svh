`ifndef L1_CACHE_WRAPPER_IF_SVH
`define L1_CACHE_WRAPPER_IF_SVH

interface l1_cache_wrapper_if(
    input logic clk
);
    logic nRST;
    logic clear, flush;
    logic clear_done, flush_done;

    modport tester
    (
        output nRST,
        output clear, flush,
        input clk, clear_done, flush_done
    ); 
   
    modport cache
    (
        input clear, flush, clk, nRST,
        output clear_done, flush_done
    ); 
endinterface

`endif
