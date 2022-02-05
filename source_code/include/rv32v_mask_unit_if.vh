`ifndef RV32V_MASK_UNIT_IF_VH
`define RV32V_MASK_UNIT_IF_VH

interface rv32v_mask_unit_if();

  logic [31:0] mask_32bit, iota_res, wdata_m_ff1, wdata_m, vs1_data, vs2_data; 
  offset_t offset;
  ma_t mask_type;
  logic mask_bit_set, mask_bit_set_ff1, busy_m, exception_m, start_ma;
    
  modport mask_unit (
    input   vs1_data, vs2_data, start_ma, mask_type, mask_32bit, iota_res, offset,
    output  wdata_m, wdata_m_ff1, busy_m, exception_m, mask_bit_set, mask_bit_set_ff1
  );


endinterface

`endif //RV32V_MASK_UNIT_IF_VH