`include "rv32v_reorder_buffer_if.vh"
`include "entry_modifier_if.vh"
`timescale 1ns/100ps

module tb_rv32v_reorder_buffer ();
  import rv32i_types_pkg::*;

  parameter PERIOD = 20;
  parameter NUM = 32;

  logic CLK, nRST;
  logic [4:0] tag0, tag1, tag2, tag3, tag4, tag5;

  rv32v_reorder_buffer_if rob_if();

  rv32v_reorder_buffer DUT (CLK, nRST, rob_if);
  
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
    rob_if.index_a = '0; 
    rob_if.index_mu = '0; 
    rob_if.index_du = '0;  
    rob_if.index_m = '0;  
    rob_if.index_p = '0;  
    rob_if.index_ls = '0;  
    rob_if.woffset_a = '0;  
    rob_if.woffset_mu = '0;  
    rob_if.woffset_du = '0;  
    rob_if.woffset_m = '0;  
    rob_if.woffset_p = '0;  
    rob_if.woffset_ls = '0;  
    rob_if.wdata_a = '0; 
    rob_if.wdata_mu = '0;  
    rob_if.wdata_du = '0;  
    rob_if.wdata_m = '0;  
    rob_if.wdata_p = '0;  
    rob_if.wdata_ls = '0;  
    rob_if.vd_a = '0; 
    rob_if.vd_mu = '0;  
    rob_if.vd_du = '0;  
    rob_if.vd_m = '0;  
    rob_if.vd_p = '0; 
    rob_if.vd_ls = '0;  
    rob_if.wen_a = '0;  
    rob_if.wen_mu = '0;  
    rob_if.wen_du = '0;  
    rob_if.wen_m = '0;  
    rob_if.wen_p = '0;  
    rob_if.wen_ls = '0;  
    rob_if.exception_a = '0;  
    rob_if.exception_mu = '0;  
    rob_if.exception_du = '0;  
    rob_if.exception_m = '0;  
    rob_if.exception_p = '0;  
    rob_if.exception_ls = '0;  
    rob_if.ready_a = '0; 
    rob_if.ready_mu = '0;  
    rob_if.ready_du = '0;  
    rob_if.ready_m = '0;  
    rob_if.ready_p = '0;  
    rob_if.ready_ls = '0;  
    rob_if.sew_a = SEW32;  
    rob_if.sew_mu = SEW32;  
    rob_if.sew_du = SEW32;  
    rob_if.sew_m = SEW32;  
    rob_if.sew_p = SEW32;  
    rob_if.sew_ls = SEW32; 
    rob_if.alloc_ena = '0;  
    rob_if.sew = SEW32; 
    rob_if.lmul = LMUL1;
    rob_if.branch_mispredict = '0; 
    rob_if.scalar_exception = '0; 
    rob_if.commit_ena = '0; 
    rob_if.vl = 4; 
    rob_if.vl_a = 4; 
    rob_if.vl_mu = 4; 
    rob_if.vl_du = 4; 
    rob_if.vl_m = 4; 
    rob_if.vl_p = 4; 
    rob_if.vl_ls = 4; 
    rob_if.exception_index_a = '0;  
    rob_if.exception_index_mu = '0;  
    rob_if.exception_index_du = '0;  
    rob_if.exception_index_m = '0;  
    rob_if.exception_index_p = '0;  
    rob_if.exception_index_ls = '0; 
    rob_if.single_bit_write = '0; 
    rob_if.single_bit_op = '0; 
  endtask

  task check_result (
    input logic [127:0] expected_wdata,
    input logic [15:0] expected_wen,
    input logic [4:0] expected_vd,
    input logic expected_exception,
    input logic expected_single_wen
  );
    static int testcase = 0;
    $display("---------- CHECKING RESULT %d ---------", testcase);
    @(posedge CLK);
    #(1);
    rob_if.commit_ena = 1;
    #(1);
    if (rob_if.commit_done) $display ("COMMIT DONE IS ON");
    else $error("WRONG: COMMIT DONE IS OFF.");
    if (rob_if.wdata_final == expected_wdata) $display ("CORRECT WDATA");
    else $error("WRONG WDATA. EXPECTED: %h. ACTUAL: %h", expected_wdata, rob_if.wdata_final);
    if (rob_if.wen_final == expected_wen) $display ("CORRECT WEN");
    else $error("WRONG WEN. EXPECTED: %h. ACTUAL: %h", expected_wen, rob_if.wen_final);
    if (rob_if.vd_final == expected_vd) $display ("CORRECT VD");
    else $error("WRONG VD. EXPECTED: %h. ACTUAL: %h", expected_vd, rob_if.vd_final);
    if (rob_if.rv32v_exception == expected_exception) $display ("CORRECT EX");
    else $error("WRONG EX. EXPECTED: %h. ACTUAL: %h", expected_exception, rob_if.rv32v_exception);
    if (rob_if.single_wen == expected_single_wen) $display ("CORRECT SB");
    else $error("WRONG SB. EXPECTED: %h. ACTUAL: %h", expected_single_wen, rob_if.single_wen);
    testcase += 1;
    @(posedge CLK);
    #(1);
    clear_input();
  endtask

  initial begin
    clear_input();
    reset_dut();
    // -------------------------------------------------------- TEST CASE 1: Get one tag --------------------------------------
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 1;
    tag0 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 0;
    @(posedge CLK);
    @(posedge CLK);
    #(1);
    rob_if.index_a = tag0; 
    rob_if.woffset_a = 0;  
    rob_if.wdata_a = {32'h11117777, 32'h9A012};
    rob_if.vd_a = 10; 
    rob_if.wen_a = 2'b11; 
    rob_if.exception_a = 0;  
    rob_if.ready_a = 1; 
    rob_if.exception_index_a = '0;  
    @(posedge CLK);
    #(1);
    rob_if.wdata_a = {32'h89120, 32'h9100};
    rob_if.woffset_a = 2; 
    @(posedge CLK);
    #(1);
    rob_if.ready_a = 0; 
    clear_input();
    // -------------------------------------------------------- TEST CASE 2: Get more than one tag --------------------------
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 1;
    tag0 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    tag1 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    tag2 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 0;
    @(posedge CLK);
    #(1);
    // ARITH 1 
    rob_if.index_a = tag0; 
    rob_if.woffset_a = 0;  
    rob_if.wdata_a = {32'hAAAABBBB, 32'hCCCCDDDD};
    rob_if.vd_a = 10; 
    rob_if.wen_a = 2'b11; 
    rob_if.exception_a = 0;  
    rob_if.ready_a = 1; 
    rob_if.exception_index_a = '0;  
    @(posedge CLK);
    #(1);
    // ARITH 2
    rob_if.wdata_a = {32'h11112222, 32'h33334444};
    rob_if.woffset_a = 2; 
    // MUL 1 
    rob_if.index_mu = tag1; 
    rob_if.woffset_mu = 0;  
    rob_if.wdata_mu = {32'h70799, 32'h81300};
    rob_if.vd_mu = 4; 
    rob_if.wen_mu = 2'b11; 
    rob_if.exception_mu = 0;  
    rob_if.ready_mu = 1; 
    rob_if.exception_index_mu = '0;  
    @(posedge CLK);
    #(1);
    // MUL 2 
    rob_if.wdata_mu = {32'h1999, 32'h2000};
    rob_if.woffset_mu = 2; 
    // DIV 1 
    rob_if.index_du = tag2; 
    rob_if.woffset_du = 0;  
    rob_if.wdata_du = {32'h77777777, 32'h88888888};
    rob_if.vd_du = 8; 
    rob_if.wen_du = 2'b11; 
    rob_if.exception_du = 0;  
    rob_if.ready_du = 1; 
    rob_if.exception_index_du = '0;  
    // ARITH OFF
    rob_if.ready_a = 0; 
    @(posedge CLK);
    #(1);
    // DIV 2 
    rob_if.wdata_du = {32'h11223344, 32'h55667788};
    rob_if.woffset_du = 2; 
    // MUL OFF
    rob_if.ready_mu = 0; 
    @(posedge CLK);
    #(1);
    // DIV OFF
    rob_if.ready_du = 0; 
    // -------------------------------------------------------- TEST CASE 3: Ready to commit -------------------------
    check_result({32'h89120, 32'h9100, 32'h11117777, 32'h9A012}, 16'hffff, 10, 0, 0);
    check_result({32'h11112222, 32'h33334444, 32'hAAAABBBB, 32'hCCCCDDDD}, 16'hffff, 10, 0, 0);
    check_result({32'h1999, 32'h2000, 32'h70799, 32'h81300}, 16'hffff, 4, 0, 0);
    check_result({32'h11223344, 32'h55667788, 32'h77777777, 32'h88888888}, 16'hffff, 8, 0, 0); 
    // -------------------------------------------------------- TEST CASE 4: Scalar flush -------------------------
    @(posedge CLK);
    #(1);
    rob_if.branch_mispredict = 1; 
    @(posedge CLK);
    #(1);
    rob_if.branch_mispredict = 0; 
    // -------------------------------------------------------- TEST CASE 5: Exception --------------------------------------
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 1;
    tag0 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 0;
    @(posedge CLK);
    @(posedge CLK);
    #(1);
    rob_if.index_a = tag0; 
    rob_if.woffset_a = 0;  
    rob_if.wdata_a = {32'h11117777, 32'h9A012};
    rob_if.vd_a = 17; 
    rob_if.wen_a = 2'b11; 
    rob_if.exception_a = 0;  
    rob_if.ready_a = 1; 
    rob_if.exception_index_a = '0;  
    @(posedge CLK);
    #(1);
    rob_if.exception_a = 1;  
    rob_if.exception_index_a = 2; 
    rob_if.wdata_a = {32'h89120, 32'h9100};
    rob_if.woffset_a = 2; 
    @(posedge CLK);
    #(1);
    rob_if.ready_a = 0; 
    clear_input();
    delay(3);
    check_result({32'h89120, 32'h9100, 32'h11117777, 32'h9A012}, 16'hff, 17, 1, 0);
    // -------------------------------------------------------- TEST CASE 6: Get one tag (lmul = 2) --------------------------------------
    clear_input();
    rob_if.lmul = LMUL2;
    rob_if.vl = 8;
    reset_dut();
    @(posedge CLK);
    #(1);
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 1;
    tag0 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 0;
    @(posedge CLK);
    @(posedge CLK);
    #(1);
    rob_if.index_ls = tag0; 
    rob_if.woffset_ls = 0;  
    rob_if.vl_ls = 8; 
    rob_if.wdata_ls = {32'h11117777, 32'h9A012};
    rob_if.vd_ls = 5; 
    rob_if.wen_ls = 2'b11; 
    rob_if.exception_ls = 0;  
    rob_if.ready_ls = 1; 
    rob_if.exception_index_ls = '0;  
    @(posedge CLK);
    #(1);
    rob_if.vl_ls = 8; 
    rob_if.wdata_ls = {32'h89120, 32'h9100};
    rob_if.woffset_ls = 2; 
    @(posedge CLK);
    #(1);
    rob_if.vl_ls = 8; 
    rob_if.wdata_ls = {32'h7901, 32'h9012};
    rob_if.woffset_ls = 4; 
    @(posedge CLK);
    #(1);
    rob_if.vl_ls = 8; 
    rob_if.wdata_ls = {32'hAAAAAAAA, 32'hBBBBBBBB};
    rob_if.woffset_ls = 6; 
    @(posedge CLK);
    #(1);
    rob_if.ready_ls = 0; 
    clear_input();
    delay(3);
    check_result({32'h89120, 32'h9100, 32'h11117777, 32'h9A012}, 16'hffff, 5, 0, 0);
    check_result({32'hAAAAAAAA, 32'hBBBBBBBB, 32'h7901, 32'h9012}, 16'hffff, 6, 0, 0);
    // -------------------------------------------------------- TEST CASE 7: Get one tag (sew = 8) --------------------------------------
    delay(2);
    clear_input();
    rob_if.sew = SEW8;
    rob_if.sew_ls = SEW8;
    rob_if.vl = 8; 
    reset_dut();
    @(posedge CLK);
    #(1);
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 1;
    tag0 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 0;
    @(posedge CLK);
    @(posedge CLK);
    #(1);
    rob_if.vl_ls = 8; 
    rob_if.sew_ls = SEW8;
    rob_if.index_ls = tag0; 
    rob_if.woffset_ls = 0;  
    rob_if.wdata_ls = {32'h77, 32'h12};
    rob_if.vd_ls = 8; 
    rob_if.wen_ls = 2'b11; 
    rob_if.exception_ls = 0;  
    rob_if.ready_ls = 1; 
    rob_if.exception_index_ls = '0;  
    @(posedge CLK);
    #(1);
    rob_if.vl_ls = 8; 
    rob_if.wdata_ls = {32'h20, 32'h91};
    rob_if.woffset_ls = 2; 
    @(posedge CLK);
    #(1);
    rob_if.vl_ls = 8; 
    rob_if.wdata_ls = {32'h01, 32'h12};
    rob_if.woffset_ls = 4; 
    @(posedge CLK);
    #(1);
    rob_if.vl_ls = 8; 
    rob_if.wdata_ls = {32'hAA, 32'hBB};
    rob_if.woffset_ls = 6; 
    @(posedge CLK);
    #(1);
    rob_if.ready_ls = 0; 
    //clear_input();
    delay(3);
    check_result({64'h0, 32'hAABB0112, 32'h20917712}, 16'hff, 8, 0, 0);
    // -------------------------------------------------------- TEST CASE 7: Get one tag (sew = 16) --------------------------------------
    delay(2);
    clear_input();
    rob_if.sew = SEW16;
    rob_if.sew_a = SEW16;
    rob_if.vl = 8; 
    reset_dut();
    @(posedge CLK);
    #(1);
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 1;
    tag0 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 0;
    @(posedge CLK);
    @(posedge CLK);
    #(1);
    rob_if.vl_a = 8; 
    rob_if.sew_a = SEW16;
    rob_if.index_a = tag0; 
    rob_if.woffset_a = 0;  
    rob_if.wdata_a = {32'h1177, 32'h1212};
    rob_if.vd_a = 8; 
    rob_if.wen_a = 2'b11; 
    rob_if.exception_a = 0;  
    rob_if.ready_a = 1; 
    rob_if.exception_index_a = '0;  
    @(posedge CLK);
    #(1);
    rob_if.vl_a = 8; 
    rob_if.wdata_a = {32'h2120, 32'h9AA1};
    rob_if.woffset_a = 2; 
    @(posedge CLK);
    #(1);
    rob_if.vl_a = 8; 
    rob_if.wdata_a = {32'h01BB, 32'h1CC2};
    rob_if.woffset_a = 4; 
    @(posedge CLK);
    #(1);
    rob_if.vl_a = 8; 
    rob_if.wdata_a = {32'hA5EA, 32'h1B0B};
    rob_if.woffset_a = 6; 
    @(posedge CLK);
    #(1);
    rob_if.ready_a = 0; 
    //clear_input();
    delay(3);
    check_result({32'hA5EA1B0B, 32'h01BB1CC2, 32'h21209AA1, 32'h11771212}, 16'hffff, 8, 0, 0);
    // -------------------------------------------------------- TEST CASE 8: Single bit write --------------------------------------
    @(posedge CLK);
    #(1);
    rob_if.alloc_ena = 1;
    rob_if.single_bit_op = 1; 
    tag0 = rob_if.cur_tail;
    @(posedge CLK);
    #(1);
    rob_if.single_bit_op = 0; 
    rob_if.alloc_ena = 0;
    @(posedge CLK);
    @(posedge CLK);
    #(1);
    rob_if.index_a = tag0; 
    rob_if.woffset_a = 0;  
    rob_if.vl_a = 4;  
    rob_if.single_bit_write = 1;
    rob_if.wdata_a = {32'h1, 32'h0};
    rob_if.vd_a = 0; 
    rob_if.wen_a = 2'b11; 
    rob_if.exception_a = 0;  
    rob_if.ready_a = 1; 
    rob_if.exception_index_a = '0;  
    @(posedge CLK);
    #(1);
    rob_if.vl_a = 4;  
    rob_if.single_bit_write = 1;
    rob_if.wdata_a = {32'h1, 32'h1};
    rob_if.woffset_a = 2; 
    @(posedge CLK);
    #(1);
    rob_if.ready_a = 0; 
    clear_input();
    delay(3);
    check_result({32'h0, 32'h0, 32'h0, 32'hE}, 16'hffff, 0, 0, 1);
    delay(20);
    $finish;
  end 
endmodule

