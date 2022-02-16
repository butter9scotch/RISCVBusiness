`ifndef ENTRY_MODIFIER_IF_VH
`define ENTRY_MODIFIER_IF_VH

interface entry_modifier_if;

  import rv32i_types_pkg::*;

  parameter NUM = 32;
  parameter LANES = 2;

  sew_t sew;
  logic [$clog2(NUM)-1:0] index, final_index;
  offset_t woffset;
  logic [4:0] vd, final_vd;
  logic [6:0] vd_outer_offset;
  logic [3:0] vd_wen_offset;
  logic filled_one_entry;

  modport em (
    input woffset, index, vd, sew,
    output vd_outer_offset, vd_wen_offset, final_index, final_vd, filled_one_entry
  );

endinterface

`endif // ENTRY_MODIFIER_IF_VH
