`ifndef L1_CACHE_WRAPPER_IF_SVH
`define L1_CACHE_WRAPPER_IF_SVH

interface l1_cache_wrapper_if(
    input logic CLK
);
    logic nRST;
    logic clear, flush;
    logic clear_done, flush_done;

    modport tester
    (
        output nRST,
        output clear, flush,
        input CLK, clear_done, flush_done
    ); 
   
    modport cache
    (
        input clear, flush, CLK, nRST,
        output clear_done, flush_done
    ); 
endinterface

`endif
