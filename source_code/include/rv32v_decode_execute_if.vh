`ifndef RV32V_DECODE_EXECUTE_IF_VH
`define RV32V_DECODE_EXECUTE_IF_VH

interface rv32v_decode_execute_if;
  import rv32v_types_pkg::*;

  logic stride_type, rd_WEN, config_type, mask0, mask1, reduction_ena, is_signed, ls_idx, load, store, wen0, wen1;
  logic [31:0] stride_val, xs1, xs2, vl, vs1_lane0, vs1_lane1, vs3_lane0, vs3_lane1, vs2_lane0, vs2_lane1, imm, storedata0, storedata1;
  logic [4:0] rd_sel;
  offset_t woffset0, woffset1;
  fu_t fu_type;
  athresult_t result_type;
  valuop_t aluop;
  rs_t rs1_type, rs2_type;

  modport decode (
    output stride_type, stride_val, xs1, xs2, rd_WEN, config_type, rd_sel, vl, vs1_lane0, vs1_lane1, vs3_lane0, vs3_lane1, rs1_type, imm, rs2_type, vs2_lane0, vs2_lane1, fu_type, result_type, woffset0, woffset1, aluop, mask0, mask1, reduction_ena, is_signed, ls_idx, load, store, storedata0, storedata1, wen0, wen1
  );


  modport execute (
    input stride_type, stride_val, xs1, xs2, rd_WEN, config_type, rd_sel, vl, vs1_lane0, vs1_lane1, vs3_lane0, vs3_lane1, rs1_type, imm, rs2_type, vs2_lane0, vs2_lane1, fu_type, result_type, woffset0, woffset1, aluop, mask0, mask1, reduction_ena, is_signed, ls_idx, load, store, storedata0, storedata1, wen0, wen1
  );

endinterface

`endif // RV32V_DECODE_EXECUTE_IF_VH
