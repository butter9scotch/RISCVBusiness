`ifndef RV32V_PERMUTATION_UNIT_IF_VH
`define RV32V_PERMUTATION_UNIT_IF_VH

interface rv32v_permutation_unit_if();

  logic [31:0] vs1_data, vs2_data, wdata_p; 
  logic busy_p, exception_p;

  modport execute (
    input   vs1_data, vs2_data, 
    output  wdata_p, busy_p, exception_p
  );

endinterface

`endif //RV32V_PERMUTATION_UNIT_IF_VH