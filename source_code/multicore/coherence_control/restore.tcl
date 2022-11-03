
# NC-Sim Command File
# TOOL:	ncsim(64)	15.20-s030
#
#
# You can restore this configuration with:
#
#      irun -access +rwc +nctimescale+1ns/1ns -incdir ../../include/ bus_ctrl.sv bus_ctrl_tb.sv -input restore.tcl
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
probe -create -database waves bus_ctrl_tb.DUT.count_complete bus_ctrl_tb.test_case_num bus_ctrl_tb.nRST bus_ctrl_tb.tb_err bus_ctrl_tb.test_case_info bus_ctrl_tb.CLK bus_ctrl_tb.ccif.ccexclusive bus_ctrl_tb.ccif.ccinv bus_ctrl_tb.ccif.ccsnoopaddr bus_ctrl_tb.ccif.ccsnoophit bus_ctrl_tb.ccif.cctrans bus_ctrl_tb.ccif.ccwait bus_ctrl_tb.ccif.ccwrite bus_ctrl_tb.ccif.dREN bus_ctrl_tb.ccif.dWEN bus_ctrl_tb.ccif.daddr bus_ctrl_tb.ccif.dload bus_ctrl_tb.ccif.dstore bus_ctrl_tb.ccif.dwait bus_ctrl_tb.ccif.l2REN bus_ctrl_tb.ccif.l2WEN bus_ctrl_tb.ccif.l2addr bus_ctrl_tb.ccif.l2load bus_ctrl_tb.ccif.l2state bus_ctrl_tb.ccif.l2store bus_ctrl_tb.DUT.state bus_ctrl_tb.DUT.nstate bus_ctrl_tb.DUT.requester_cpu bus_ctrl_tb.DUT.nrequester_cpu bus_ctrl_tb.DUT.nsupplier_cpu bus_ctrl_tb.DUT.supplier_cpu bus_ctrl_tb.DUT.nosupplier

simvision -input restore.tcl.svcf
