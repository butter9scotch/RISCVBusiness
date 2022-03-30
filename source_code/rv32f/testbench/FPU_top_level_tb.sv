`timescale 1 ns / 1ns

`include "FPU_if.vh"
module FPU_top_level_tb();
    parameter PERIOD = 10;

    logic nRST, CLK = 0;

    //clock generation
    always #(PERIOD/2) CLK++;

    //fpu interface
    FPU_if fpu_if(nRST, CLK);

    //module instantiations

    FPU_top_level DUT(fpu_if);

    clock_counter cc(fpu_if);

    test PROG(CLK, nRST, fpu_if);
endmodule

program test(
    input logic CLK,
    output logic nRST,
    FPU_if.tb fpu_if
);

    parameter PERIOD = 10;
    word_t expected_fpu_out;
    word_t expected_flags;
    int test_case_num;
    string test_case;
    int sample_num;

    task reset_dut; begin
        nRST = 1'b0;
        @(posedge CLK);
        @(posedge CLK);

        @(negedge CLK);
        nRST = 1'b1;

        @(posedge CLK);
        @(posedge CLK);
    end
    endtask

    task wait_for_finish; begin
    @(posedge CLK);
    while (!fpu_if.f_ready) #(PERIOD);
    end
    endtask

    task check_outputs; begin
        #(2ns);
        if (expected_flags !== fpu_if.f_flags) begin
            $error("Incorrect flags for test case #%d: %s, expected: %b obtained: %b\n", test_case_num, test_case, expected_flags, fpu_if.f_flags);
            return ;
        end
        if (expected_fpu_out !== fpu_if.fpu_out) begin
            $error("Incorrect output value for test case #%d: %s, expected: %x %f obtained: %h %f\n", test_case_num, test_case, expected_fpu_out, expected_fpu_out, fpu_if.fpu_out, fpu_if.fpu_out);
        end
        $info("Correct output values for test case %d: %s\n", test_case_num, test_case);
    end
    endtask
        
    initial begin
        reset_dut;
        fpu_if.port_a = 32'h40b4cccd;
        fpu_if.port_b = 32'hc1865014;
        fpu_if.f_frm_in = 0;
        fpu_if.f_funct_7 = 0;
        test_case_num = 1;
        test_case = "add test case";
        sample_num = 1;
        //wait_for_finish;
        expected_flags = 0;
        expected_fpu_out = 32'hc13239c2;
        #(3 * PERIOD);
        check_outputs;
        $finish;
    end
endprogram
