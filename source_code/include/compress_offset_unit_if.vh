`ifndef COMPRESS_OFFSET_UNIT_IF_VH
`define COMPRESS_OFFSET_UNIT_IF_VH

interface compress_offset_unit_if;

  import rv32i_types_pkg::*;

  logic ena, busy, checking_mask0_1, done;
  offset_t woffset0, woffset1;
  logic [1:0] wen, vs1_mask;


  modport compress_offset_unit (
    input ena, done, vs1_mask,
    output wen, woffset0, woffset1, busy
  );

endinterface

`endif //COMPRESS_OFFSET_UNIT_IF_VH

  
