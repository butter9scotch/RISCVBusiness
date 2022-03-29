`include "vector_lane_if.vh"

module vloadstore_unit (
  vector_lane_if.vloadstore_unit lsif
);

  logic [31:0] portb;
  assign lsif.in_addr = lsif.porta_sel ? lsif.porta1 : lsif.porta0;
  assign portb = lsif.portb_sel ? lsif.portb1 : lsif.portb0;
  assign lsif.out_addr = lsif.in_addr + portb;
  assign lsif.wdata_ls = lsif.portb_sel ? lsif.out_addr : lsif.in_addr;
endmodule

