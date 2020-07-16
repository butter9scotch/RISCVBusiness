
# NC-Sim Command File
# TOOL:	ncsim(64)	15.20-s030
#
#
# You can restore this configuration with:
#
#      irun -access +rwc +nctimescale+1ns/1ns -coverage all -covoverwrite -define MAPPED /package/asicfab/MITLL_90_Dec2019/MITLL90_STDLIB_8T/2019.12.20//MITLL90_STDLIB_8T.v fpu.v source/tb_FPU_top_level.sv -input restore.tcl
#

set tcl_prompt1 {puts -nonewline "ncsim> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
alias . run
alias iprof profile
alias quit exit
database -open -shm -into waves.shm waves -default
probe -create -database waves tb_FPU_top_level.clk tb_FPU_top_level.flags tb_FPU_top_level.floating_point1 tb_FPU_top_level.floating_point2 tb_FPU_top_level.floating_point_out tb_FPU_top_level.fp1_real tb_FPU_top_level.fp2_real tb_FPU_top_level.fp_exp tb_FPU_top_level.fp_frac tb_FPU_top_level.fp_out_real tb_FPU_top_level.frm tb_FPU_top_level.funct7 tb_FPU_top_level.i tb_FPU_top_level.j tb_FPU_top_level.nrst tb_FPU_top_level.result_binary tb_FPU_top_level.result_real tb_FPU_top_level.DUT.add_carry_out tb_FPU_top_level.DUT.add_exp_max tb_FPU_top_level.DUT.add_floating_point_out tb_FPU_top_level.DUT.add_sign_out tb_FPU_top_level.DUT.add_sum tb_FPU_top_level.DUT.clk tb_FPU_top_level.DUT.cmp_out tb_FPU_top_level.DUT.exp_max tb_FPU_top_level.DUT.exp_max_minus tb_FPU_top_level.DUT.flag_add tb_FPU_top_level.DUT.flag_sub tb_FPU_top_level.DUT.flags tb_FPU_top_level.DUT.floating_point1 tb_FPU_top_level.DUT.floating_point2 tb_FPU_top_level.DUT.floating_point_out tb_FPU_top_level.DUT.frac_not_shifted tb_FPU_top_level.DUT.frac_not_shifted_minus tb_FPU_top_level.DUT.frac_shifted tb_FPU_top_level.DUT.frac_shifted_minus tb_FPU_top_level.DUT.frm tb_FPU_top_level.DUT.frm2 tb_FPU_top_level.DUT.frm3 tb_FPU_top_level.DUT.funct7 tb_FPU_top_level.DUT.funct7_2 tb_FPU_top_level.DUT.funct7_3 tb_FPU_top_level.DUT.inexact tb_FPU_top_level.DUT.inexact_sub tb_FPU_top_level.DUT.inv3 tb_FPU_top_level.DUT.minus_carry_out tb_FPU_top_level.DUT.minus_exp_max tb_FPU_top_level.DUT.minus_sign_out tb_FPU_top_level.DUT.minus_sum tb_FPU_top_level.DUT.mul_carry_out tb_FPU_top_level.DUT.mul_ovf tb_FPU_top_level.DUT.mul_sign_out tb_FPU_top_level.DUT.mul_unf tb_FPU_top_level.DUT.negmul_floating_point_out tb_FPU_top_level.DUT.nrst tb_FPU_top_level.DUT.o tb_FPU_top_level.DUT.outallone tb_FPU_top_level.DUT.outallzero tb_FPU_top_level.DUT.ovf tb_FPU_top_level.DUT.ovf_sub tb_FPU_top_level.DUT.product tb_FPU_top_level.DUT.sign_not_shifted tb_FPU_top_level.DUT.sign_not_shifted_minus tb_FPU_top_level.DUT.sign_shifted tb_FPU_top_level.DUT.sign_shifted_minus tb_FPU_top_level.DUT.signout tb_FPU_top_level.DUT.step1_to_step2 tb_FPU_top_level.DUT.step2_to_step3 tb_FPU_top_level.DUT.sum_exp tb_FPU_top_level.DUT.sum_init tb_FPU_top_level.DUT.unf tb_FPU_top_level.DUT.unf_sub tb_FPU_top_level.DUT.unsigned_exp_diff tb_FPU_top_level.DUT.wm

simvision -input restore.tcl.svcf
