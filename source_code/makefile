##############################################################################
# File Related Variables
##############################################################################


PIPELINE = pipelines
PIPE5    = $(PIPELINE)/pipe5
STD_CORE = standard_core
BRANCH_PREDICT := branch_predictors
PREDICTOR_FILES := $(BRANCH_PREDICT)/branch_predictor_wrapper.sv $(BRANCH_PREDICT)/nottaken_predictor/nottaken_predictor.sv
CACHES = caches

PRIV_FILES := privs/priv_wrapper.sv  privs/priv_1_11/priv_1_11_block.sv  privs/priv_1_11/priv_1_11_control.sv  privs/priv_1_11/priv_1_11_csr_rfile.sv  privs/priv_1_11/priv_1_11_pipeline_control.sv
PIPE5FILES = $(PIPE5)/src/pipe5_fetch1_stage.sv $(PIPE5)/src/pipe5_fetch2_stage.sv $(PIPE5)/src/pipe5_decode_stage.sv $(PIPE5)/src/pipe5_execute_stage.sv $(PIPE5)/src/pipe5_memory_stage.sv $(PIPE5)/src/pipe5_writeback_stage.sv $(PIPE5)/src/pipe5_forwarding_unit.sv standard_core/RISCVBusiness.sv $(PIPE5)/src/pipe5_hazard_unit.sv standard_core/memory_controller.sv $(CACHES)/caches_wrapper.sv $(CACHES)/pass_through/pass_through_cache.sv $(CACHES)/separate_caches.sv tb/tb_RISCVBusiness_self_test.sv ram/config_ram_wrapper.sv  ram/ram_sim_model.sv ram/ram_wrapper.sv 
#Header Files
HEADER_FILES := -incdir ./include  
PKG_FILES :=  packages/rv32i_types_pkg.sv packages/alu_types_pkg.sv packages/machine_mode_types_1_11_pkg.sv  packages/machine_mode_types_pkg.sv packages/pipe5_types_pkg.sv  packages/rv32f_types_pkg.sv
STANDARD_CORE_FILES := $(STD_CORE)/alu.sv $(STD_CORE)/branch_res.sv $(STD_CORE)/control_unit.sv $(STD_CORE)/dmem_extender.sv $(STD_CORE)/endian_swapper.sv $(STD_CORE)/jump_calc.sv $(STD_CORE)/rv32i_reg_file.sv
TRACKER_FILES := trackers/branch_tracker.sv trackers/cpu_tracker.sv
EXTRAS := caches/direct_mapped_tpf/direct_mapped_tpf_cache.sv bus_bridges/generic_nonpipeline.sv 
FPU_FILES:=rv32f/rv32f_reg_file.sv rv32f/FPU_top_level.sv rv32f/clock_counter.sv rv32f/ADD_step1.sv rv32f/ADD_step2.sv rv32f/ADD_step3.sv rv32f/SUB_step1.sv rv32f/SUB_step2.sv rv32f/SUB_step3.sv rv32f/MUL_step1.sv rv32f/MUL_step2.sv rv32f/mul_26b.sv rv32f/determine_frac_status.sv rv32f/int_comparesub.sv rv32f/sign_determine.sv rv32f/int_compare.sv rv32f/right_shift.sv rv32f/u_to_s.sv rv32f/c_to_cp.sv rv32f/sub_26b.sv rv32f/s_to_u.sv rv32f/adder_26b.sv rv32f/adder_8b.sv rv32f/left_shift.sv rv32f/subtract.sv rv32f/rounder_sub.sv rv32f/rounder.sv

##############################################################################
# Usage Definition
##############################################################################

define USAGE
@echo "----------------------------------------------------------------"
@echo "Administrative targets:"
@echo "  clean         - removes the temporary files"
@echo	"  print_vars  - prints the contents of the variables"
@echo
@echo "Simulation targets:"
@echo "  source     - compiles and simulates the source version"
@echo "----------------------------------------------------------------"
endef

##############################################################################
# Designate targets that do not correspond directly to files so that they are
# run every time they are called
##############################################################################
.phony: default clean 
.phony: sim_source sim_mapped_ti sim_mapped_osu
.phony: syn_mapped

##############################################################################
# Make the default target (the one called when no specific one is invoked) to
# output the proper usage of this makefile
##############################################################################
default:
	$(USAGE)

##############################################################################
# Administrative Targets
##############################################################################

clean:
	@echo -e "Removing temporary files"
	@rm -rf source_work mapped_work
	@rm -rf analyzed/ARCH analyzed/ENTI
	@rm -rf INCA_libs/
	@rm -f analyzed/*
	@rm -f schematic/*
	@rm -f *.wlf *.svf transcript
	@rm -f *.tran
	@rm -f *.comp
	@rm -f mmmc.view
	@rm -f *.rpt
	@rm -f *.cmd*
	@rm -f *.log*
	@rm -f *.rpt.old
	@rm -f irun.*
	@echo -e "Done\n\n"
	
print_vars:
	@echo -e "Component Files: \n $(foreach file, $(COMPONENT_FILES_VHD) $(COMPONENT_FILES_V), $(file)\n)"
	@echo -e "Top level File: $(TOP_LEVEL_FILE)"
	@echo -e "Arch to mapp: $(MAPPED_ARCH)"
	@echo -e "Testbench: $(TEST_BENCH)"


##############################################################################
# Synthesis Target
##############################################################################

source:
	@irun  -access +rwc -timescale 1ns/100ps -shm  $(PKG_FILES) $(HEADER_FILES) $(FPU_FILES) $(STANDARD_CORE_FILES) $(PIPE5FILES) $(PREDICTOR_FILES) $(EXTRAS) $(PRIV_FILES) $(TRACKER_FILES)


