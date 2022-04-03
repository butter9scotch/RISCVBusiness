`include "completion_buffer_if.vh"
`timescale 1ns/100ps

module tb_completion_buffer ();
  import rv32i_types_pkg::*;

  parameter PERIOD = 20;
  parameter NUM = 16;

  logic CLK, nRST;
  logic [4:0] tag0, tag1, tag2, tag3, tag4, tag5;

  completion_buffer_if cb_if();

  completion_buffer DUT (CLK, nRST, cb_if);
  
  always begin
    CLK = 0;
    #(PERIOD/2.0);
    CLK=1;
    #(PERIOD/2.0);
  end

  task delay;
    input integer i;
  begin
    for (int j = 0; j < i; j++) begin
      @(posedge CLK);
    end
  end
  endtask 

  task reset_dut();
    @(negedge CLK);
    nRST = 0;
    @(posedge CLK);
    @(posedge CLK);
    #(PERIOD/4.0);
    nRST = 1;
    @(posedge CLK);
  endtask

  task clear_input();
    cb_if.alloc_ena = '0;
    cb_if.rv32v_instr = '0;
    cb_if.v_commit_done = '0; 
    cb_if.rv32v_exception = '0;
    cb_if.rv32v_wb_scalar_ena = '0; 
    cb_if.rv32v_wb_scalar_ready = '0; 
    cb_if.rv32v_wb_exception = '0;
    cb_if.rv32v_wb_scalar_index = '0; 
    cb_if.rv32v_wb_vd = '0;
    cb_if.rv32v_wb_scalar_data = '0; 
    cb_if.index_a = '0;
    cb_if.index_mu = '0; 
    cb_if.index_du = '0; 
    cb_if.index_ls = '0; 
    cb_if.wdata_a = '0; 
    cb_if.wdata_mu = '0; 
    cb_if.wdata_du = '0; 
    cb_if.wdata_ls = '0; 
    cb_if.vd_a = '0;
    cb_if.vd_mu = '0; 
    cb_if.vd_du = '0; 
    cb_if.vd_ls = '0; 
    cb_if.exception_a = '0; 
    cb_if.exception_mu = '0; 
    cb_if.exception_du = '0; 
    cb_if.exception_ls = '0; 
    cb_if.ready_a = '0;
    cb_if.ready_mu = '0; 
    cb_if.ready_du = '0; 
    cb_if.ready_ls = '0; 
    cb_if.branch_mispredict = '0;
    cb_if.wen_a = '0;
    cb_if.valid_a = '0;
    cb_if.mal_ls = '0;
  endtask

  task clear_a();
    cb_if.index_a = '0; 
    cb_if.wdata_a = '0;
    cb_if.vd_a = '0; 
    cb_if.exception_a = '0;  
    cb_if.ready_a = '0; 
    cb_if.wen_a = '0;
    cb_if.valid_a = '0;
  endtask

  task clear_ls();
    cb_if.index_ls = '0; 
    cb_if.wdata_ls = '0;
    cb_if.vd_ls = '0; 
    cb_if.exception_ls = '0;  
    cb_if.ready_ls = '0; 
    cb_if.mal_ls = '0;
  endtask

  task clear_mu();
    cb_if.index_mu = '0; 
    cb_if.wdata_mu = '0;
    cb_if.vd_mu = '0; 
    cb_if.exception_mu = '0;  
    cb_if.ready_mu = '0; 
  endtask

  task clear_du();
    cb_if.index_du = '0; 
    cb_if.wdata_du = '0;
    cb_if.vd_du = '0; 
    cb_if.exception_du = '0;  
    cb_if.ready_du = '0; 
  endtask

  task clear_v_wb();
    cb_if.rv32v_wb_scalar_index = '0;
    cb_if.rv32v_wb_scalar_ready = '0;
    cb_if.rv32v_wb_scalar_data = '0;
    cb_if.rv32v_wb_vd = 0;
    cb_if.rv32v_wb_exception = 0;
  endtask

  task check_result (
    input logic [31:0] expected_wdata,
    input logic [4:0] expected_vd,
    input logic expected_flush,
    input logic expected_scalar_commit_ena,
    input logic expected_rv32v_commit_ena,
    input logic expected_branch_mis
  );
    static int testcase = 0;
    $display("---------- CHECKING RESULT %d ---------", testcase);
    @(posedge CLK);
    //@(posedge cb_if.tb_read);
    #(1);
    clear_input();
    if (cb_if.scalar_commit_ena == expected_scalar_commit_ena) $display ("CORRECT SCALAR COMMIT ENA");
    else $error("WRONG SCALAR COMMIT ENA. EXPECTED: %h. ACTUAL: %h", expected_scalar_commit_ena, cb_if.scalar_commit_ena);
    if (cb_if.v_commit_ena == expected_rv32v_commit_ena) $display ("CORRECT RV32V COMMIT ENA");
    else $error("WRONG RV32V COMMIT ENA. EXPECTED: %h. ACTUAL: %h", expected_rv32v_commit_ena, cb_if.v_commit_ena);
    if (cb_if.wdata_final == expected_wdata) $display ("CORRECT WDATA");
    else $error("WRONG WDATA. EXPECTED: %h. ACTUAL: %h", expected_wdata, cb_if.wdata_final);
    if (cb_if.vd_final == expected_vd) $display ("CORRECT VD");
    else $error("WRONG VD. EXPECTED: %h. ACTUAL: %h", expected_vd, cb_if.vd_final);
    if (cb_if.flush == expected_flush) $display ("CORRECT FLUSH");
    else $error("WRONG FLUSH. EXPECTED: %h. ACTUAL: %h", expected_flush, cb_if.flush);
    if (cb_if.branch_mispredict_ena == expected_branch_mis) $display ("CORRECT BRANCH MISPREDICT");
    else $error("WRONG BRANCH MISPREDICT. EXPECTED: %h. ACTUAL: %h", expected_branch_mis, cb_if.branch_mispredict_ena);
    testcase += 1; 
    //@(posedge CLK);
    //#(1);
    //clear_input();
  endtask

  initial begin
    clear_input();
    reset_dut();
    // -------------------------------------------------------- TEST CASE 1: Get one tag --------------------------------------
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 1;
    tag0 = cb_if.cur_tail;
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 0;
    @(posedge CLK);
    @(posedge CLK);
    #(1);
    cb_if.index_a = tag0; 
    cb_if.wdata_a = 32'h1234567;
    cb_if.vd_a = 10; 
    cb_if.exception_a = 0;  
    cb_if.ready_a = 1; 
    cb_if.wen_a = 1;
    cb_if.valid_a = 1;
    check_result(32'h1234567, 10, 0, 1, 0, 0);
    delay(10);
    // -------------------------------------------------------- TEST CASE 2: Get more than one tag --------------------------
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 1;
    tag0 = cb_if.cur_tail; // FOR DIV
    @(posedge CLK);
    #(1);
    tag1 = cb_if.cur_tail; // FOR LS
    @(posedge CLK);
    #(1);
    tag2 = cb_if.cur_tail; // FOR MUL
    @(posedge CLK);
    #(1);
    tag3 = cb_if.cur_tail; // FOR ARIT
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 0;
    @(posedge CLK);
    #(1);
    // ARITH  
    cb_if.index_a = tag3; 
    cb_if.wdata_a = 32'hABCD1234;
    cb_if.vd_a = 7; 
    cb_if.exception_a = 0;  
    cb_if.ready_a = 1; 
    cb_if.wen_a = 1;
    cb_if.valid_a = 1;
    // LOADSTORE
    cb_if.index_ls = tag1; 
    cb_if.wdata_ls = 32'h11116666;
    cb_if.vd_ls = 3; 
    cb_if.exception_ls = 0;  
    cb_if.ready_ls = 1; 
    @(posedge CLK);
    #(1);
    clear_a();
    clear_ls();
    @(posedge CLK);
    #(1);
    // MUL
    cb_if.index_mu = tag2; 
    cb_if.wdata_mu = 32'hA005681;
    cb_if.vd_mu = 11; 
    cb_if.exception_mu = 0;  
    cb_if.ready_mu = 1; 
    @(posedge CLK);
    #(1);
    clear_mu();
    delay(10);
    @(posedge CLK);
    #(1);
    // DIV
    cb_if.index_du = tag0; 
    cb_if.wdata_du = 32'hA005681;
    cb_if.vd_du = 1; 
    cb_if.exception_du = 0;  
    cb_if.ready_du = 1; 
    check_result(32'hA005681, 1, 0, 1, 0, 0);
    check_result(32'h11116666, 3, 0, 1, 0, 0);
    check_result(32'hA005681, 11, 0, 1, 0, 0);
    check_result(32'hABCD1234, 7, 0, 1, 0, 0);
    @(posedge CLK);
    #(1);
    //clear_du();
    delay(5);
    // -------------------------------------------------------- TEST CASE 3: Exception --------------------------------------
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 1;
    tag0 = cb_if.cur_tail;
    @(posedge CLK);
    #(1);
    tag1 = cb_if.cur_tail; 
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 0;
    @(posedge CLK);
    #(1);
    cb_if.index_a = tag1; 
    cb_if.wdata_a = 32'h77779999;
    cb_if.vd_a = 17; 
    cb_if.exception_a = 0;  
    cb_if.ready_a = 1; 
    cb_if.wen_a = 0;
    cb_if.valid_a = 0;
    delay(5);
    @(posedge CLK);
    #(1);
    cb_if.index_du = tag0; 
    cb_if.wdata_du = 32'hFFFFFFFF;
    cb_if.vd_du = 21; 
    cb_if.exception_du = 1;  
    cb_if.ready_du = 1; 
    check_result(32'hFFFFFFFF, 21, 1, 0, 0, 0);
    delay(3);
    // -------------------------------------------------------- TEST CASE 4: Branch misprediction --------------------------------------
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 1;
    tag0 = cb_if.cur_tail;
    @(posedge CLK);
    #(1);
    tag1 = cb_if.cur_tail; 
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 0;
    @(posedge CLK);
    #(1);
    cb_if.index_ls = tag1; 
    cb_if.wdata_ls = 32'h77779999;
    cb_if.vd_ls = 17; 
    cb_if.exception_ls = 0;  
    cb_if.ready_ls = 1; 
    delay(5);
    @(posedge CLK);
    #(1);
    cb_if.index_a = tag0; 
    cb_if.wdata_a = 32'hFFFFFFFF;
    cb_if.vd_a = 21; 
    cb_if.exception_a = 0;  
    cb_if.ready_a = 1; 
    cb_if.branch_mispredict = 1;
    cb_if.wen_a = 0;
    cb_if.valid_a = '0;
    check_result(32'hFFFFFFFF, 21, 1, 0, 0, 1);
    delay(3);
    // -------------------------------------------------------- TEST CASE 5: RV32V --------------------------------------
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 1; // DIV
    tag0 = cb_if.cur_tail;
    @(posedge CLK);
    #(1);
    tag1 = cb_if.cur_tail; // rv32v instr writes back to scalar
    cb_if.rv32v_instr = 1;
    cb_if.rv32v_wb_scalar_ena = 1;
    @(posedge CLK);
    #(1);
    tag2 = cb_if.cur_tail; // MUL
    cb_if.rv32v_instr = 0;
    cb_if.rv32v_wb_scalar_ena = 0; 
    @(posedge CLK);
    #(1);
    tag3 = cb_if.cur_tail; // rv32v instr does not write back to scalar
    cb_if.rv32v_instr = 1;
    cb_if.rv32v_wb_scalar_ena = 0; 
    @(posedge CLK);
    #(1);
    cb_if.rv32v_instr = 0;
    cb_if.alloc_ena = 1;
    tag4 = cb_if.cur_tail; // ARITH
    @(posedge CLK);
    #(1);
    cb_if.alloc_ena = 0;
    @(posedge CLK);
    #(1);
    // ARITH  
    cb_if.index_a = tag4; 
    cb_if.wdata_a = 32'hABCD1234;
    cb_if.vd_a = 7; 
    cb_if.exception_a = 0;  
    cb_if.ready_a = 1; 
    cb_if.wen_a = 1;
    cb_if.valid_a = 1;
    // V-WB
    cb_if.rv32v_wb_scalar_index = tag1;
    cb_if.rv32v_wb_scalar_ready = 1;
    cb_if.rv32v_wb_scalar_data = 32'h79;
    cb_if.rv32v_wb_vd = 9;
    cb_if.rv32v_wb_exception = 0;
    @(posedge CLK);
    #(1);
    clear_a();
    clear_v_wb();
    // MUL  
    cb_if.index_mu = tag2; 
    cb_if.wdata_mu = 32'hFF4;
    cb_if.vd_mu = 1; 
    cb_if.exception_mu = 0;  
    cb_if.ready_mu = 1; 
    @(posedge CLK);
    #(1);
    clear_mu();
    // DIV  
    cb_if.index_du = tag0; 
    cb_if.wdata_du = 32'h65FF1;
    cb_if.vd_du = 11; 
    cb_if.exception_du = 0;  
    cb_if.ready_du = 1; 
    check_result(32'h65FF1, 11, 0, 1, 0, 0);
    check_result(32'h79, 9, 0, 1, 0, 0);
    check_result(32'hFF4, 1, 0, 1, 0, 0);
    check_result(32'h0, 0, 0, 0, 1, 0); // dummy wait (RV32V takes multiple cycles to ack)
    @(posedge CLK);
    #(1);
    cb_if.v_commit_done = 1;
    check_result(32'hABCD1234, 7, 0, 1, 0, 0); 
    delay(3);
    $finish;
  end 
endmodule

