
`include "component_selection_defines.vh"
`include "pipe5_fetch1_fetch2_if.vh"
`include "pipe5_decode_execute_if.vh"
`include "pipe5_execute_mem_if.vh"
`include "pipe5_mem_writeback_if.vh"
`include "pipe5_forwarding_unit_if.vh"
`include "rv32i_reg_file_if.vh"
`include "jump_calc_if.vh"
`include "branch_res_if.vh"
`include "rv32i_reg_file_if.vh"
`include  "predictor_pipeline_if.vh"
`include "generic_bus_if.vh"

module pipe5();



   //interface
   pipe5_fetch1_fetch2_if fetch1_fetch2_if();
   pipe5_fetch2_decode_if fetch_decode_if();
   pipe5_decode_execute_if decode_execute_if();
   pipe5_execute_mem_if execute_mem_if();
   pipe5_mem_writeback_if mem_wb_if();
   pipe5_forwarding_unit_if bypass_if();
   rv32i_reg_file_if rf_if();
   predictor_pipeline_if predict_if();
   jump_calc_if jump_if();
   branch_res_if branch_if();
   generic_bus_if igen_bus_if();
   generic_bus_if dgen_bus_if();
   cache_control_if  cc_if();

   //module instantiations

   pipe5_fetch1_stage fetch1_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.fetch1_fetch2_if(fetch1_fetch2_if)
       ,.predict_if(predict_if)
      );

   pipe5_fetch2_stage fetch2_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.fetch1_fetch2_if(fetch1_fetch2_if)
       ,.fetch_decode_if(fetch_decode_if)
       ,.igen_bus_if(igen_bus_if)
      );

   pipe5_decode_stage decode_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.fetch_decode_if(fetch_decode_if)
       ,.decode_execute_if(decode_execute_if)
       ,.rf_if(rf_if)
      );

   pipe5_execute_stage execute_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.decode_execute_if(decode_execute_if)
       ,.execute_mem_if(execute_mem_if)
       ,.bypass_if(bypass_if)
       ,.jump_if(jump_if)
       ,.branch_if(branch_if)
      );

   pipe5_memory_stage memory_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.execute_mem_if(execute_mem_if)
       ,.mem_wb_if(mem_wb_if)
       ,.bypass_if(bypass_if)
       ,.jump_if(jump_if)
       ,.branch_if(branch_if)
       ,.dgen_bus_if(dgen_bus_if)
       ,.predict_if(predict_if)
       ,.cc_if(cc_if)
      );


   pipe5_writeback_stage writeback_stage (
        .CLK(CLK)
       ,.nRST(nRST)
       ,.mem_wb_if(mem_wb_if)
       ,.bypass_if(bypass_if)
       ,.rf_if(rf_if)
      );

   rv32i_reg_file rg_file (.*);
   branch_res branch_res (.br_if(branch_if));
   jump_calc jump_calc (.jump_if(jump_if));
   pipe5_forwarding_unit forwarding_unit (.bypass_if(bypass_if));
   
   //Halt logic
   //assign halt = 






endmodule
