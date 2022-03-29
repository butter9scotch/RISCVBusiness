`ifndef IOTA_LOGIC_IF_VH
`define IOTA_LOGIC_IF_VH

interface iota_logic_if;
  import rv32i_types_pkg::*;
  logic [63:0] mask_bits;
  logic start;
  sew_t sew;
  logic [VL_WIDTH-1:0] max;
  logic busy;
  logic [31:0] res0, res1;

  modport iota_logic (
    input   mask_bits, start, sew, max,
    output  res0, res1, busy
  );

endinterface

`endif //IOTA_LOGIC_IF_VH
