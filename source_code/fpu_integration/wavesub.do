onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/clk
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/nrst
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/floating_point1
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/floating_point2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/frm
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/funct7
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/floating_point_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/flags
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/frm2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/frm3
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/funct7_2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/funct7_3
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/sign_shifted
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/sign_shifted_minus
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/frac_shifted
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/frac_shifted_minus
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/sign_not_shifted
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/sign_not_shifted_minus
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/frac_not_shifted
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/frac_not_shifted_minus
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/exp_max
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/exp_max_minus
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/mul_sign1
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/mul_sign2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/mul_exp1
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/mul_exp2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/product
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/mul_carry_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/step1_to_step2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/nxt_step1_to_step2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/add_sign_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/add_sum
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/add_carry_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/add_exp_max
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/minus_sign_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/minus_sum
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/minus_carry_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/minus_exp_max
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/cmp_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/cmp_out_det
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/fp1_sign
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/fp1_frac
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/fp2_sign
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/fp2_frac
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/mul_sign_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/sum_exp
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/mul_ovf
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/mul_unf
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/inv
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/inv2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/inv3
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/step2_to_step3
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/nxt_step2_to_step3
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/exp_determine
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/bothnegsub
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/bothpossub
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/n1p2
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/n1p2r
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/signout
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/same_compare
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/shifted_check_allone
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/shifted_check_onezero
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/unsigned_exp_diff
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/frac_same
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/wm
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/ovf
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/unf
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/inexact
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/ovf_sub
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/unf_sub
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/inexact_sub
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/flag_add
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/flag_sub
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/sum_init
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/outallone
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/outallzero
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/o
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/negmul_floating_point_out
add wave -noupdate -expand -group dut -radix binary /tb_FPU_top_level/DUT/add_floating_point_out
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/sum_init
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/unsigned_exp_diff
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/n1p2r
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/wm
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/clk
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/nrst
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/frac_shifted_minus
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/outallzero
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/outallone
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/same_compare
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/bothnegsub
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/cmp_out
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/floating_point1
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/floating_point2
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/function_mode
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/ovf_in
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/unf_in
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/dz
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/inv
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/frm
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/exponent_max_in
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/sign_in
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/frac_in
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/carry_out
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/shifted_check_allone
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/shifted_check_onezero
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/before_floating_point_out
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/ovf
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/unf
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/inexact
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/sign
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/exponent
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/frac
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/shifted_frac
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/shifted_amount
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/exp_out
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/temp_sign
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/dummy_floating_point_out
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/fp_option
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/hold_value
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/rounded_frac
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/round_this
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/log_de
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/round_out
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/buf_determine
add wave -noupdate -expand -group sub_step3 -radix binary /tb_FPU_top_level/DUT/sub_step3/round_flag
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/sum_init
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/clk
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/nrst
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/unsigned_exp_diff
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/frac_in
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/shifted_frac
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/n1p2r
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/wm
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/shifted_amount
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/buf_determine
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/frac_shifted_minus
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/outallzero
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/outallone
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/same_compare
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/bothnegsub
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/cmp_out
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/fp1
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/fp2
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/frm
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/sign
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/exp_in
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/fraction
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/carry_out
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/shifted_check_allone
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/shifted_check_onezero
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/round_out
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/rounded
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/sol_frac
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/round_amount
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/temp_round_out
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/temp_fraction
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/temp_exp
add wave -noupdate -expand -group rounder_sub -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/mod
add wave -noupdate -expand -group rounder_sub -color Gold -radix binary /tb_FPU_top_level/DUT/sub_step3/ROUND/flag_inexact
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/n1p2r
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/shifted_check_onezero
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/fp1
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/fp2
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/cmp_out
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/frac1
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/frac2
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/frac1_s
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/frac2_s
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/n1p2
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/bothpossub
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/sum
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/ovf
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/outallone
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/outallzero
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/wm
add wave -noupdate -expand -group sub_signed_frac -radix binary /tb_FPU_top_level/DUT/sub_step2/sub_signed_fracs/sum_init
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {6037010000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 235
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
WaveRestoreZoom {6036999378 ps} {6037020622 ps}
