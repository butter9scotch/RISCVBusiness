`ifndef RV32V_EXECUTE_MEMORY_IF_VH
`define RV32V_EXECUTE_MEMORY_IF_VH

interface rv32v_execute_memory_if;
  import rv32v_types_pkg::*;

  logic load, store, wen0, wen1;
  logic [31:0] storedata0, storedata1, aluresult0, aluresult1;
  offset_t woffset0, woffset1;
  logic config_type;
  logic [31:0] vl;
  logic [31:0] vtype;

  modport execute (
    output load, store, storedata0, storedata1, aluresult0, aluresult1, wen0, wen1, woffset0, woffset1,
    config_type, vl, vtype
  );


  modport memory (
    input load, store, storedata0, storedata1, aluresult0, aluresult1, wen0, wen1, woffset0, woffset1,
    config_type, vl, vtype

  );

endinterface

`endif // RV32V_EXECUTE_MEMORY_IF_VH
