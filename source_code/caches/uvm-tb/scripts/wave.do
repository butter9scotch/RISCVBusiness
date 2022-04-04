onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group cpu_bus_if /tb_caches_top/cpu_bus_if/addr
add wave -noupdate -expand -group cpu_bus_if /tb_caches_top/cpu_bus_if/wdata
add wave -noupdate -expand -group cpu_bus_if /tb_caches_top/cpu_bus_if/rdata
add wave -noupdate -expand -group cpu_bus_if -color Cyan /tb_caches_top/cpu_bus_if/ren
add wave -noupdate -expand -group cpu_bus_if -color Coral /tb_caches_top/cpu_bus_if/wen
add wave -noupdate -expand -group cpu_bus_if /tb_caches_top/cpu_bus_if/busy
add wave -noupdate -expand -group cpu_bus_if /tb_caches_top/cpu_bus_if/byte_en
add wave -noupdate -expand -group i_l1_arb_bus_if /tb_caches_top/i_l1_arb_bus_if/addr
add wave -noupdate -expand -group i_l1_arb_bus_if /tb_caches_top/i_l1_arb_bus_if/wdata
add wave -noupdate -expand -group i_l1_arb_bus_if /tb_caches_top/i_l1_arb_bus_if/rdata
add wave -noupdate -expand -group i_l1_arb_bus_if -color Cyan /tb_caches_top/i_l1_arb_bus_if/ren
add wave -noupdate -expand -group i_l1_arb_bus_if -color Coral /tb_caches_top/i_l1_arb_bus_if/wen
add wave -noupdate -expand -group i_l1_arb_bus_if /tb_caches_top/i_l1_arb_bus_if/busy
add wave -noupdate -expand -group i_l1_arb_bus_if /tb_caches_top/i_l1_arb_bus_if/byte_en
add wave -noupdate -expand -group cif /tb_caches_top/cif/CLK
add wave -noupdate -expand -group cif /tb_caches_top/cif/nRST
add wave -noupdate -expand -group cif /tb_caches_top/cif/clear
add wave -noupdate -expand -group cif /tb_caches_top/cif/flush
add wave -noupdate -expand -group cif /tb_caches_top/cif/clear_done
add wave -noupdate -expand -group cif /tb_caches_top/cif/flush_done
add wave -noupdate -group mem_cif /tb_caches_top/mem_cif/CLK
add wave -noupdate -group mem_cif /tb_caches_top/mem_cif/nRST
add wave -noupdate -group mem_cif /tb_caches_top/mem_cif/clear
add wave -noupdate -group mem_cif /tb_caches_top/mem_cif/flush
add wave -noupdate -group mem_cif /tb_caches_top/mem_cif/clear_done
add wave -noupdate -group mem_cif /tb_caches_top/mem_cif/flush_done
add wave -noupdate -group l1 /tb_caches_top/l1/set_num
add wave -noupdate -group l1 /tb_caches_top/l1/next_set_num
add wave -noupdate -group l1 /tb_caches_top/l1/en_set_ctr
add wave -noupdate -group l1 /tb_caches_top/l1/clr_set_ctr
add wave -noupdate -group l1 /tb_caches_top/l1/frame_num
add wave -noupdate -group l1 /tb_caches_top/l1/next_frame_num
add wave -noupdate -group l1 /tb_caches_top/l1/en_frame_ctr
add wave -noupdate -group l1 /tb_caches_top/l1/clr_frame_ctr
add wave -noupdate -group l1 /tb_caches_top/l1/word_num
add wave -noupdate -group l1 /tb_caches_top/l1/next_word_num
add wave -noupdate -group l1 /tb_caches_top/l1/en_word_ctr
add wave -noupdate -group l1 /tb_caches_top/l1/clr_word_ctr
add wave -noupdate -group l1 /tb_caches_top/l1/finish_word
add wave -noupdate -group l1 /tb_caches_top/l1/finish_frame
add wave -noupdate -group l1 /tb_caches_top/l1/finish_set
add wave -noupdate -group l1 /tb_caches_top/l1/state
add wave -noupdate -group l1 /tb_caches_top/l1/next_state
add wave -noupdate -group l1 /tb_caches_top/l1/decoded_addr
add wave -noupdate -group l1 /tb_caches_top/l1/hit
add wave -noupdate -group l1 /tb_caches_top/l1/pass_through
add wave -noupdate -group l1 /tb_caches_top/l1/hit_data
add wave -noupdate -group l1 /tb_caches_top/l1/hit_idx
add wave -noupdate -group l1 /tb_caches_top/l1/ridx
add wave -noupdate -group l1 /tb_caches_top/l1/read_addr
add wave -noupdate -group l1 /tb_caches_top/l1/next_read_addr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1018500 ps} 0}
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
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {388500 ps}
