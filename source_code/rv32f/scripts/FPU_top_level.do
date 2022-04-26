onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/n_rst
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/clk
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/port_a
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/port_b
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/f_frm_in
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/f_flags
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/f_funct_7
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/fpu_out
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/f_ready
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/exp_max
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/floating_point1_in
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/floating_point2_in
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/floating_point_not_shift
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/floating_point_shift
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/frac_not_shifted
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/frac_shifted
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/funct7
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/unsigned_exp_diff
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/sign_not_shifted
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/sign_shifted
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/exp_max
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/floating_point1_in
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/floating_point2_in
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/floating_point_not_shift
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/floating_point_shift
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/frac_not_shifted
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/frac_shifted
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/funct7
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/unsigned_exp_diff
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/sign_not_shifted
add wave -noupdate -expand -group add_step1 -color Wheat /FPU_top_level_tb/DUT/addStep1/sign_shifted
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/frac1
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sign1
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/frac2
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sign2
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/exp_max_in
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sign_out
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sum
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/carry_out
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/exp_max_out
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/frac1_signed
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/frac2_signed
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sum_signed
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/frac1
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sign1
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/frac2
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sign2
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/exp_max_in
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sign_out
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sum
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/carry_out
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/exp_max_out
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/frac1_signed
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/frac2_signed
add wave -noupdate -expand -group {add step 2} -color {Cadet Blue} /FPU_top_level_tb/DUT/add_step2/sum_signed
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/n_rst
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/clk
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/port_a
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/port_b
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/f_frm_in
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/f_flags
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/f_funct_7
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/fpu_out
add wave -noupdate /FPU_top_level_tb/DUT/fpu_if/f_ready
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/out_of_range
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/mul_ovf
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/mul_carry_out
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/function_mode
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/floating_point1
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/floating_point2
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/ovf_in
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/unf_in
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/dz
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/inv
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/frm
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/exponent_max_in
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/sign_in
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/frac_in
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/carry_out
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/add_floating_point_out
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/ovf
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/unf
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/inexact
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/sign
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/exponent
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/frac
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/dummy_floating_point_out
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/exp_minus_shift_amount
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/shifted_frac
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/shifted_amount
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/exp_out
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/round_this
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/fp_option
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/round_out
add wave -noupdate -expand -group add_step3 -color Yellow /FPU_top_level_tb/DUT/add_step3/round_flag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ns} 0}
quietly wave cursor active 0
configure wave -namecolwidth 293
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {73 ns}
