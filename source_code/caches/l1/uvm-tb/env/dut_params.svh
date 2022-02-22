`ifndef DUT_PARAMS_SVH
`define DUT_PARAMS_SVH

`define NONCACHE_START_ADDR 32'h8000_0000

`define L1_BLOCK_SIZE 4
`define L1_CACHE_SIZE 2048
`define L1_ASSOC 2

//32 bit addr - word offset - byte offset
`define L1_FRAME_INDEX_BITS ($clog2(`L1_CACHE_SIZE / `L1_ASSOC / `L1_BLOCK_SIZE))
`define L1_WORD_INDEX_BITS ($clog2(`L1_BLOCK_SIZE))
`define L1_TAG_BITS (32 - `L1_FRAME_INDEX_BITS - `L1_WORD_INDEX_BITS - 2)

`endif