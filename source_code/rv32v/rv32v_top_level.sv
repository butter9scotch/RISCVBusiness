module rv32v_top_level(  
  input logic CLK, nRST, 
  rv32v_fetch2_decode_if.decode  fetch_decode_if,
  cache_model_if.memory cif,
  rv32v_hazard_unit_if hu_if,
  prv_pipeline_if prv_if,
  output logic rd_wen,
  output logic [4:0] rd_sel,
  output logic [31:0] rd_data,
  input logic [31:0] xs1, xs2,
  input logic scalar_hazard_if_ret,
  input logic returnex
);




  // rv32v_fetch2_decode_if  fetch_decode_if();
  rv32v_decode_execute_if decode_execute_if();
  rv32v_execute_memory_if execute_memory_if();
  rv32v_memory_writeback_if memory_writeback_if();
  // cache_model_if cif(); // TODO: Remove/Change this during integration
  rv32v_reg_file_if rfv_if();
  // rv32v_hazard_unit_if hu_if();
  // prv_pipeline_if prv_if();
  // rv32v_reg_file_if rfv_if();

  rv32v_decode_stage  decode_stage (.*);
  rv32v_execute_stage execute_stage(.*);
  rv32v_memory_stage mem_stage(.*);
  rv32v_writeback_stage writeback_stage(.*);
  
  rv32v_hazard_unit hazard_unit(.*);
  rv32v_reg_file reg_file(.*);
  //wb



  
  
endmodule