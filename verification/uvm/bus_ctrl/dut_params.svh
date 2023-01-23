`ifndef DUT_PARAMS_SVH
`define DUT_PARAMS_SVH

package dut_params;

localparam NUM_CPUS_USED 2;
localparam BLOCK_SIZE_WORDS 2;
localparam WORD_W 32;
localparam DRVR_TIMEOUT 50;

// Structure to hold the snoop resposne information that the driver uses
typedef struct packed {
  // Array of addresses that will provide a snoop hit response
  // Use the address to index this array and the dirty array
  rand bit [$clog2(dut_params::WORD_W)-1:0] snooHitAddr; // if 1 at address index then hit
  rand bit [$clog2(dut_params::WORD_W)-1:0] snoopDirty;  // if 1 at address index thn dirty
} drvr_snoop_t;

endpackage
`endif
