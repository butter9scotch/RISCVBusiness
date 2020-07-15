onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/frm
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/floating_point1
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/floating_point2
add wave -noupdate -expand -group f_ready -color Gold -radix binary /tb_FPU_top_level/clk
add wave -noupdate -expand -group f_ready -color Gold -radix binary /tb_FPU_top_level/nrst
add wave -noupdate -expand -group f_ready -color Gold -radix binary /tb_FPU_top_level/floating_point_out
add wave -noupdate -expand -group f_ready -color Gold -radix binary /tb_FPU_top_level/f_ready
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/funct7
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/flags
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/start_sig
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/result_real
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/result_binary
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/fp1_real
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/fp2_real
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/fp_out_real
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/fp_exp
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/fp_frac
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/i
add wave -noupdate -expand -group f_ready -radix binary /tb_FPU_top_level/j
add wave -noupdate -expand -group DUT -color Gold -radix binary /tb_FPU_top_level/DUT/clk
add wave -noupdate -expand -group DUT -color Gold -radix binary /tb_FPU_top_level/DUT/nrst
add wave -noupdate -expand -group DUT -radix binary /tb_FPU_top_level/DUT/floating_point1
add wave -noupdate -expand -group DUT -radix binary /tb_FPU_top_level/DUT/floating_point2
add wave -noupdate -expand -group DUT -radix binary /tb_FPU_top_level/DUT/frm
add wave -noupdate -expand -group DUT -radix binary /tb_FPU_top_level/DUT/funct7
add wave -noupdate -expand -group DUT -color Gold -radix binary /tb_FPU_top_level/DUT/start_sig
add wave -noupdate -expand -group DUT -radix binary /tb_FPU_top_level/DUT/floating_point_out
add wave -noupdate -expand -group DUT -radix binary /tb_FPU_top_level/DUT/flags
add wave -noupdate -expand -group DUT -color Gold -radix binary /tb_FPU_top_level/DUT/f_ready
add wave -noupdate -expand -group DUT -color Gold -radix binary /tb_FPU_top_level/DUT/dummy_start
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {48785 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 186
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
WaveRestoreZoom {16458 ps} {84754 ps}
