`include "vector_lane_if.vh"

module loadstore_unit (
  vector_lane_if.loadstore_unit lsif
);

  logic [31:0] portb;
  assign lsif.in_addr = lsif.porta_sel ? lsif.porta1 : lsif.porta0;
  assign portb = lsif.portb_sel ? lsif.portb1 : lsif.portb0;
  assign lsif.out_addr = lsif.in_addr + portb;
endmodule

