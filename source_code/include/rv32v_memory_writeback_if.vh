`ifndef RV32V_MEMORY_WRITEBACK_IF_VH
`define RV32V_MEMORY_WRITEBACK_IF_VH

interface rv32v_memory_writeback_if;
  import rv32v_types_pkg::*;

  logic [31:0] wdat0, wdat1;
  logic wen0, wen1;
  offset_t woffset0, woffset1;
  sew_t sew;
  vlmul_t mul;

  modport memory (
    output wdat0, wdat1, wen0, wen1, woffset0, woffset1, sew, mul
  );


  modport writeback (
    input wdat0, wdat1, wen0, wen1, woffset0, woffset1 
  );

  modport decode (
    input sew, mul
  );

endinterface

`endif // RV32V_MEMORY_WRITEBACK_IF_VH
