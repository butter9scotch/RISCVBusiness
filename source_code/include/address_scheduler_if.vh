`ifndef ADDRESS_SCHEDULER_IF_VH
`define ADDRESS_SCHEDULER_IF_VH

interface address_scheduler_if;
  import rv32i_types_pkg::*;
  logic [31:0] addr0, addr1, storedata0, storedata1;
  logic [31:0] final_addr, final_storedata;
  logic [1:0] byte_ena;
  logic load, store, dhit, wen, ren, arrived0, arrived1, returnex, exception, busy;
  sew_t sew;

  modport address_scheduler (
    input   addr0, addr1, storedata0, storedata1, dhit, sew, returnex, load, store,
    output  final_addr, final_storedata, wen, ren, arrived0, arrived1, exception, busy, byte_ena
  );

endinterface

`endif //ADDRESS_SCHEDULER_IF_VH
