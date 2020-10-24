set_attribute information_level 11

set_attribute lib_search_path /package/asicfab/MITLL_90_Dec2019/MITLL90_STDLIB_8T/2019.12.20

set_attribute library MITLL90_STDLIB_8T.tt1p2v25c.lib

set_attr hdl_search_path { ./src ./include ./tb_include }

# No idea what this does...

set_attribute hdl_undriven_output_port_value 0
set_attribute use_tiehilo_for_const duplicate

read_hdl -sv ./source/FPU_top_level.sv
read_hdl -sv ./source/adder_8b.sv
read_hdl -sv ./source/mul_26b.sv
read_hdl -sv ./source/left_shift.sv
read_hdl -sv ./source/subtract.sv
read_hdl -sv ./source/rounder.sv
read_hdl -sv ./source/rounder_sub.sv
read_hdl -sv ./source/int_compare.sv
read_hdl -sv ./source/right_shift.sv
read_hdl -sv ./source/u_to_s.sv
read_hdl -sv ./source/adder_26b.sv
read_hdl -sv ./source/s_to_u.sv
read_hdl -sv ./source/ADD_step1.sv
read_hdl -sv ./source/ADD_step2.sv
read_hdl -sv ./source/ADD_step3.sv
read_hdl -sv ./source/MUL_step1.sv
read_hdl -sv ./source/MUL_step2.sv
read_hdl -sv ./source/SUB_step1.sv
read_hdl -sv ./source/SUB_step2.sv
read_hdl -sv ./source/sub_26b.sv
read_hdl -sv ./source/sign_determine.sv
read_hdl -sv ./source/subtracter_8b.sv
read_hdl -sv ./source/c_to_cp.sv
read_hdl -sv ./source/right_shift_minus.sv
read_hdl -sv ./source/SUB_step3.sv
read_hdl -sv ./source/int_comparesub.sv
read_hdl -sv ./source/determine_frac_status.sv

elaborate FPU_top_level

#insert_tiehilo_cells -hi tiehi_1x -lo tielo_1x -maxfanout 1 -verbose

set clock [define_clock -period 10000 -name clock1 clk]

# Need to change to set_clock_latency?

#external_delay -input 50000 -clock $clock /designs/*/ports_in/*

#external_delay -output 50000 -clock $clock /designs/*/ports_out/*

#Specify the external capacitive load on a port using the external_pin_cap attribute. The specified load will be calculated in femtofarads. The following example specifies an external capacitive load of 2 femtofarads on all output ports in the gia design:

#set_attribute external_pin_cap 2 /designs/gia/ports_out/*

synthesize -effort low -to_mapped

report timing -worst 20 > fpu.timing-lint.rpt

report clocks > fpu.clocks.rpt

report area >> fpu.area.rpt

write_hdl > fpu.v

write_sdc > fpu.sdc_gen

quit
