`ifndef ADDRESS_SCHEDULER_IF_VH
`define ADDRESS_SCHEDULER_IF_VH

interface address_scheduler_if;
  import rv32i_types_pkg::*;
  logic [31:0] addr0, addr1, storedata0, storedata1;
  logic [31:0] final_addr, final_storedata, vl;
  logic [1:0] byte_ena;
  logic load_ena, store_ena, dhit, wen, ren, arrived0, arrived1, returnex, exception, busy, ls_idx, segment_type;
  width_t eew_loadstore;
  sew_t sew;
  offset_t woffset1;

  modport address_scheduler (
    input   addr0, addr1, storedata0, storedata1, dhit, sew, returnex, load_ena, store_ena, vl, woffset1, ls_idx, eew_loadstore, segment_type,
    output  final_addr, final_storedata, wen, ren, arrived0, arrived1, exception, busy, byte_ena
  );

endinterface

`endif //ADDRESS_SCHEDULER_IF_VH
