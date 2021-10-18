`include "vector_lane_if.vh"

module vector_lane (
  input logic CLK, nRST,
  vector_lane_if vif
);

  import rv32v_types_pkg::*;

  // Instantiate all functional unit

  arithmetic_unit AU (
    .CLK(CLK),
    .nRST(nRST),
    .au_if(vif)
  );
/*
  permutation_unit PU (
    .CLK(CLK),
    .nRST(nRST),
    .pu_if(vif)
  );
  
  mask_unit MU (
    .mu_if(vif)
  ); */

  load_store_unit LSU (
    .lsu_if(vif)
  ); 

  // Connecting signals
  logic au, ru, mlu, dv, mau, pu, lu, su;
  assign au  = vif.fu_type == ARITH;
  assign ru  = vif.fu_type == RED;
  assign mlu = vif.fu_type == MUL;
  assign dv  = vif.fu_type == DIV;
  assign mau = vif.fu_type == MASK;
  assign pu  = vif.fu_type == PEM;
  assign lu  = vif.fu_type == LOAD;
  assign su  = vif.fu_type == STORE;

  // Output sel
  assign vif.busy        = vif.busy_a | vif.busy_p | vif.busy_m | vif.busy_ls;
  assign vif.exception   = vif.exception_a | vif.exception_p | vif.exception_m | vif.exception_ls;
  assign vif.lane_result = (au | ru | mlu | dv) ? vif.wdata_a :
                           (mau) ? vif.wdata_m :
                           (pu) ? vif.wdata_p :
                           (lu | su) ? vif.wdata_ls :
                           32'd0;

endmodule
