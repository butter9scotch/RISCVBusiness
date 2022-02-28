
`include "component_selection_defines.vh"
`include "ooo_fetch1_fetch2_if.vh"
`include "ooo_decode_execute_if.vh"
`include "ooo_execute_commit_if.vh"
`include "rv32i_reg_file_if.vh"
`include "jump_calc_if.vh"
`include "branch_res_if.vh"
`include  "predictor_pipeline_if.vh"
`include "generic_bus_if.vh"
`include "completion_buffer_if.vh"

module ooo();

   //interface
   ooo_fetch1_fetch2_if fetch1_fetch2_if();
   ooo_fetch2_decode_if fetch_decode_if();
   ooo_decode_execute_if decode_execute_if();
   ooo_execute_comm_if execute_comm_if();
   rv32i_reg_file_if rf_if();
   predictor_pipeline_if predict_if();
   jump_calc_if jump_if();
   branch_res_if branch_if();
   generic_bus_if igen_bus_if();
   generic_bus_if dgen_bus_if();
   cache_control_if  cc_if();
   completion_buffer_if  cb_if();

   //module instantiations

   ooo_fetch1_stage fetch1_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.fetch1_fetch2_if(fetch1_fetch2_if)
       ,.predict_if(predict_if)
      );

   ooo_fetch2_stage fetch2_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.fetch1_fetch2_if(fetch1_fetch2_if)
       ,.fetch_decode_if(fetch_decode_if)
       ,.igen_bus_if(igen_bus_if)
      );

   ooo_decode_stage decode_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.fetch_decode_if(fetch_decode_if)
       ,.decode_execute_if(decode_execute_if)
       ,.rf_if(rf_if)
       ,.hazard_if(hazard_if)
       ,.cb_if(cb_if)
      );

   ooo_execute_stage execute_stage(
      .CLK(CLK)
      ,.nRST(nRST)
      ,.halt(halt)
      ,.decode_execute_if(decode_execute_if)
      ,.execute_comm_if(execute_comm_if)
      ,.jump_if(jump_if)
      ,.predict_if(predict_if)
      ,.hazard_if(hazard_if)
      ,.branch_if(branch_if)
      ,.cc_if(cc_if)
      ,.prv_pipe_if(prv_pipe_if)
      ,.dgen_bus_if(dgen_bus_if)
   );

   ooo_commit_stage writeback_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.decode_execute_if(decode_execute_if)
       ,.execute_comm_if(execute_comm_if)
       ,.hazard_if(hazard_if)
       ,.cb_if(cb_if)
      );


   completion_buffer completion_buffer (CLK, nRST, cb_if);
   rv32i_reg_file rg_file (.*);
   branch_res branch_res (.br_if(branch_if));
   jump_calc jump_calc (.jump_if(jump_if));

   // Connect completion buffer to reg
   assign rf_if.rd = cb_if.vd_final;
   assign rf_if.w_data = cb_if.wdata_final;
   assign rf_if.wen = cb_if.scalar_commit_ena;  
   

endmodule
