`include "rv32v_hazard_unit_if.vh"

module rv32v_hazard_unit (
  rv32v_hazard_unit_if.hazard_unit huif
);
  //import rv32v_types_pkg::*;

  // TODO: Add exception signal to flush

  // fetch1 stage
  assign huif.flush_f1 = huif.csr_update; // TODO: Edit this when integration
  assign huif.stall_f1 = huif.busy_mem | huif.busy_ex | huif.busy_dec; // TODO: Edit this when integration

  // fetch2 stage
  assign huif.flush_f2 = huif.csr_update; // TODO: Edit this when integration
  assign huif.stall_f2 = huif.busy_mem | huif.busy_ex | huif.busy_dec; // TODO: Edit this when integration

  // decode stage
  assign huif.flush_dec = huif.csr_update;
  assign huif.stall_dec = huif.busy_mem | huif.busy_ex | huif.busy_dec;

  // execute stage
  assign huif.flush_ex = huif.csr_update;
  assign huif.stall_ex = huif.busy_mem | huif.busy_ex;

  // memory stage
  assign huif.flush_mem = 0;
  assign huif.stall_mem = huif.busy_mem;

endmodule
