onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/function_mode
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/floating_point1
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/floating_point2
add wave -noupdate -expand -group add_step3 -color Gold -radix binary /tb_FPU_top_level/DUT/add_step3/mul_ovf
add wave -noupdate -expand -group add_step3 -color Gold -radix binary /tb_FPU_top_level/DUT/add_step3/mul_carry_out
add wave -noupdate -expand -group add_step3 -color Gold -radix binary /tb_FPU_top_level/DUT/add_step3/ovf_in
add wave -noupdate -expand -group add_step3 -color Gold -radix binary /tb_FPU_top_level/DUT/add_step3/unf_in
add wave -noupdate -expand -group add_step3 -color Gold -radix binary /tb_FPU_top_level/DUT/add_step3/dz
add wave -noupdate -expand -group add_step3 -color Gold -radix binary /tb_FPU_top_level/DUT/add_step3/inv
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/frm
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/exponent_max_in
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/sign_in
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/frac_in
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/carry_out
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/add_floating_point_out
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/ovf
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/unf
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/inexact
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/sign
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/exponent
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/frac
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/dummy_floating_point_out
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/exp_minus_shift_amount
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/shifted_frac
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/shifted_amount
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/exp_out
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/round_this
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/fp_option
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/round_out
add wave -noupdate -expand -group add_step3 -radix binary /tb_FPU_top_level/DUT/add_step3/round_flag
add wave -noupdate -expand -group mul_step1 -radix binary /tb_FPU_top_level/DUT/mulStep1/fp1_in
add wave -noupdate -expand -group mul_step1 -radix binary /tb_FPU_top_level/DUT/mulStep1/fp2_in
add wave -noupdate -expand -group mul_step1 -color Gold -radix binary /tb_FPU_top_level/DUT/mulStep1/sign1
add wave -noupdate -expand -group mul_step1 -color Gold -radix binary /tb_FPU_top_level/DUT/mulStep1/sign2
add wave -noupdate -expand -group mul_step1 -radix binary /tb_FPU_top_level/DUT/mulStep1/exp1
add wave -noupdate -expand -group mul_step1 -radix binary /tb_FPU_top_level/DUT/mulStep1/exp2
add wave -noupdate -expand -group mul_step1 -radix binary /tb_FPU_top_level/DUT/mulStep1/product
add wave -noupdate -expand -group mul_step1 -color Gold -radix binary /tb_FPU_top_level/DUT/mulStep1/carry_out
add wave -noupdate -expand -group mul_step2 -color Gold -radix binary /tb_FPU_top_level/DUT/mul_step2/sign1
add wave -noupdate -expand -group mul_step2 -color Gold -radix binary /tb_FPU_top_level/DUT/mul_step2/sign2
add wave -noupdate -expand -group mul_step2 -radix binary /tb_FPU_top_level/DUT/mul_step2/exp1
add wave -noupdate -expand -group mul_step2 -radix binary /tb_FPU_top_level/DUT/mul_step2/exp2
add wave -noupdate -expand -group mul_step2 -color Gold -radix binary /tb_FPU_top_level/DUT/mul_step2/sign_out
add wave -noupdate -expand -group mul_step2 -radix binary /tb_FPU_top_level/DUT/mul_step2/sum_exp
add wave -noupdate -expand -group mul_step2 -color Gold -radix binary /tb_FPU_top_level/DUT/mul_step2/ovf
add wave -noupdate -expand -group mul_step2 -color Gold -radix binary /tb_FPU_top_level/DUT/mul_step2/unf
add wave -noupdate -expand -group mul_step2 -color Gold -radix binary /tb_FPU_top_level/DUT/mul_step2/carry
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {25146679 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {25144 ns} {25160 ns}
