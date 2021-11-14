`include "rv32v_memory_writeback_if.vh"
`include "rv32v_reg_file_if.vh"

module rv32v_writeback_stage(
  input logic CLK, nRST,
  rv32v_memory_writeback_if.writeback memory_writeback_if,
  rv32v_reg_file_if.writeback rfv_if
);

  import rv32v_types_pkg::*;

  assign rfv_if.w_data = {memory_writeback_if.wdat0, memory_writeback_if.wdat1};
  // assign rfv_if.wen = {memory_writeback_if.wen1, memory_writeback_if.wen0};
  assign rfv_if.wen = 2'b11;
  assign rfv_if.vd_offset = {memory_writeback_if.woffset1, memory_writeback_if.woffset1}; 
  
  assign rfv_if.vd = memory_writeback_if.vd;
  assign rfv_if.eew = memory_writeback_if.eew;
  assign rfv_if.vl = memory_writeback_if.vl;
  assign rfv_if.single_bit_write = memory_writeback_if.single_bit_write;



endmodule