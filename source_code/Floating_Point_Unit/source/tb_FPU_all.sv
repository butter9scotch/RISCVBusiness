`include "subtracter_8b.sv"
`include "f_register_file.sv"
`include "ADD_step2.sv"
`include "rv32i_types_pkg.sv"
`include "ADD_step3.sv"
`include "int_compare.sv"
`include "s_to_u.sv"
`include "subtract.sv"
`include "c_to_cp.sv"
`include "MUL_step1.sv"
`include "int_comparesub.sv"
`include "sign_determine.sv"
`include "u_to_s.sv"
`include "SUB_step3.sv"
`include "rounder_sub.sv"
`include "converter.sv"
`include "SUB_step2.sv"
`include "SUB_step1.sv"
`include "adder_26b.sv"
`include "max_select.sv"
`include "MUL_step2.sv"
`include "determine_frac_status.sv"
`include "FPU_all.sv"
`include "rounder.sv"
`include "adder_8b.sv"
`include "FPU_top_level.sv"
`include "sub_26b.sv"
`include "right_shift_minus.sv"
`include "mul_26b.sv"
`include "left_shift.sv"
`include "right_shift.sv"
`include "ADD_step1.sv"
// TODO: finishe the inclusion
`include "UVM_FPU_test.svh"

module tb_FPU_all ();
  import uvm_pkg::*;
  logic clk; 
  logic n_rst;
  //Generates clock
	initial begin
		clk = 0;
		forever #10 clk = !clk;
	end

  initial begin 
    n_rst=0;
    @(posedge clk);
    n_rst=1;
	end

  FPU_if FPUif(n_rst, clk);

  FPU_all DUT(FPUif.fp);


  initial begin
    uvm_config_db#(virtual FPU_if)::set( null, "", "vif", FPUif);

    run_test("FPU_test");
  end



endmodule


