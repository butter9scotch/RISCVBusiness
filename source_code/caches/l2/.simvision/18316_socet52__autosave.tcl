
# NC-Sim Command File
# TOOL:	ncsim(64)	15.20-s030
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
probe -create -database waves tb_l2_cache.test_case tb_l2_cache.test_number tb_l2_cache.tb_nRST tb_l2_cache.tb_CLK tb_l2_cache.l2.cache tb_l2_cache.l2.clear tb_l2_cache.l2.clear_done tb_l2_cache.l2.clr_frame_ctr tb_l2_cache.l2.clr_set_ctr tb_l2_cache.l2.clr_word_ctr tb_l2_cache.l2.decoded_addr tb_l2_cache.l2.en_frame_ctr tb_l2_cache.l2.en_set_ctr tb_l2_cache.l2.en_word_ctr tb_l2_cache.l2.finish_frame tb_l2_cache.l2.finish_set tb_l2_cache.l2.finish_word tb_l2_cache.l2.flush tb_l2_cache.l2.flush_done tb_l2_cache.l2.frame_num tb_l2_cache.l2.hit tb_l2_cache.l2.hit_data tb_l2_cache.l2.hit_idx tb_l2_cache.l2.lru tb_l2_cache.l2.nRST tb_l2_cache.l2.next_cache tb_l2_cache.l2.next_frame_num tb_l2_cache.l2.next_read_addr tb_l2_cache.l2.next_set_num tb_l2_cache.l2.next_word_num tb_l2_cache.l2.nextlru tb_l2_cache.l2.pass_through tb_l2_cache.l2.read_addr tb_l2_cache.l2.ridx tb_l2_cache.l2.set_num tb_l2_cache.l2.next_state tb_l2_cache.l2.state tb_l2_cache.l2.word_num tb_l2_cache.mem_gen_bus_if.cpu.addr tb_l2_cache.mem_gen_bus_if.cpu.busy tb_l2_cache.mem_gen_bus_if.cpu.byte_en tb_l2_cache.mem_gen_bus_if.cpu.rdata tb_l2_cache.mem_gen_bus_if.cpu.ren tb_l2_cache.mem_gen_bus_if.cpu.wdata tb_l2_cache.mem_gen_bus_if.cpu.wen tb_l2_cache.cache_gen_bus_if.generic_bus.addr tb_l2_cache.cache_gen_bus_if.generic_bus.busy tb_l2_cache.cache_gen_bus_if.generic_bus.byte_en tb_l2_cache.cache_gen_bus_if.generic_bus.rdata tb_l2_cache.cache_gen_bus_if.generic_bus.ren tb_l2_cache.cache_gen_bus_if.generic_bus.wdata tb_l2_cache.cache_gen_bus_if.generic_bus.wen

simvision -input /home/asicfab/a/socet52/Caches/RISCVBusiness/source_code/caches/l2/.simvision/18316_socet52__autosave.tcl.svcf
