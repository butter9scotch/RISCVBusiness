`include "rv32v_reorder_buffer_if.vh"

module rv32v_top_level(  
  input logic CLK, nRST, 
  cache_model_if.memory cif,
  rv32v_hazard_unit_if hu_if,
  prv_pipeline_if prv_if,
  rv32v_top_level_if.rv32v rv32v_if,
  rv32v_reorder_buffer_if rob_if,
  output logic v_ex_decode_done
);

  // Outputs
  logic rd_wen;
  logic [4:0] rd_sel;
  logic [31:0] rd_data;
  logic [31:0] xs1, xs2;
  logic done;
  logic decode_done;
  logic returnex;
  logic scalar_hazard_if_ret;

  //change this to scalar_vector_if
  scalar_vector_decode_if  scalar_vector_if();

  rv32v_decode_execute_if decode_execute_if();
  rv32v_execute_memory_if execute_memory_if();
  rv32v_memory_writeback_if memory_writeback_if();
  rv32v_reg_file_if rfv_if();


  rv32v_decode_stage  decode_stage(.*);
  rv32v_execute_stage execute_stage(.*);
  rv32v_memory_stage mem_stage(.*);
  rv32v_writeback_stage writeback_stage(.*);
  
  rv32v_hazard_unit hazard_unit(.*);
  rv32v_reg_file reg_file(.*);
  rv32v_reorder_buffer rob(.*);
  
  assign rv32v_if.rd_wen = rd_wen;
  assign rv32v_if.rd_sel = rd_sel;
  assign rv32v_if.rd_data = rd_data;
  assign rv32v_if.done = rob_if.v_done;
  assign rv32v_if.v_commit_done = rob_if.commit_done;
  // do this weird thing 
  assign rv32v_if.rob_index = rob_if.cur_tail;

  // Inputs
  assign xs1 = rv32v_if.rs1_data;
  assign xs2 = rv32v_if.rs2_data;
  assign scalar_hazard_if_ret = rv32v_if.scalar_hazard_if_ret;
  assign returnex = rv32v_if.returnex;
  assign rob_if.alloc_ena = rv32v_if.alloc_ena;
  assign rob_if.lmul = rv32v_if.lmul;
  assign rob_if.commit_ena = rv32v_if.v_commit_ena;

  assign scalar_vector_if.instr = rv32v_if.instr;
  assign scalar_vector_if.base_address_offset = rv32v_if.base_address_offset;
  assign scalar_vector_if.index = rv32v_if.index;
  assign scalar_vector_if.v_single_bit_op = rv32v_if.v_single_bit_op;
  assign scalar_vector_if.v_start = rv32v_if.v_start;

  assign v_ex_decode_done = hu_if.v_decode_done;

endmodule
