`ifndef CACHE_MODEL_IF_VH
`define CACHE_MODEL_IF_VH

interface cache_model_if;
  import rv32v_types_pkg::*;

  logic dhit, ren, wen;
  logic [1:0] byte_ena;
  logic [31:0] dmemload, dmemstore, dmemaddr;

  modport memory (
    input dhit, dmemload,
    output dmemstore, dmemaddr, ren, wen, byte_ena
  );


endinterface

`endif // CACHE_MODEL_IF_VH
