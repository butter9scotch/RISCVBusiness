#RISCVBUSINESS PROJECT ROOT DIRECTORY
ROOT = ../../..
TOP = caches_top
WAVES = scripts
COVERAGE = coverage
CPU_AGENT = cpu_agent
MEM_AGENT = mem_agent
END2END = end2end
BUS_COMPS = generic_bus_agent_comps
BFM = bfm
ENV = env
SEQUENCES = sequences
TEST = tests
INCLUDE = $(ROOT)/source_code/include
PACKAGES = $(ROOT)/source_code/packages
UTILS = utils
L1 = $(ROOT)/source_code/caches/l1
L2 = $(ROOT)/source_code/caches/l2

TESTCASE = random
VERBOSITY = LOW
SEED = random

#env_config parameters
#TODO: THIS SHOULD PROBABLY BE 8, 4 for evict WB and 4 for read
MEM_TIMEOUT = 11
MEM_LATENCY = 1
MMIO_LATENCY = 1
ITERATIONS = 0

RUN_COMMON = \
	tb_$(TOP) -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	-sv_seed $(SEED) \
	+UVM_TESTNAME=$(TESTCASE)_test \
	+UVM_VERBOSITY=UVM_$(VERBOSITY) \
	+uvm_set_config_int=*,iterations,$(ITERATIONS) \
	+uvm_set_config_int=*,mem_timeout,$(MEM_TIMEOUT) \
	+uvm_set_config_int=*,mem_latency,$(MEM_LATENCY) \
	+uvm_set_config_int=*,mmio_latency,$(MMIO_LATENCY) \
	-do "coverage save -onexit -p $(COVERAGE)/$(TESTCASE).ucdb"

POST_RUN = python post-run.py \
			$(TESTCASE) \
			$(ITERATIONS) \
			$(MEM_TIMEOUT) \
			$(MEM_LATENCY) \
			$(MMIO_LATENCY) \

all: build run

gui: build run_gui

build: 
	vlog \
	+incdir+$(L1) \
	+incdir+$(L2) \
	+incdir+$(INCLUDE) \
	+incdir+$(PACKAGES) \
	+incdir+$(UTILS) \
	+incdir+$(CPU_AGENT) \
	+incdir+$(MEM_AGENT) \
	+incdir+$(END2END) \
	+incdir+$(BUS_COMPS) \
	+incdir+$(BFM) \
	+incdir+$(ENV) \
	+incdir+$(SEQUENCES) \
	+incdir+$(TEST) \
	+acc \
	+cover \
	-L $$QUESTA_HOME/uvm-1.2 tb_$(TOP).sv 

run_gui:
	vsim -i \
	$(RUN_COMMON) \
	-do "do $(WAVES)/wave.do" \
	-do "run -all"
	$(POST_RUN)

run:
	vsim -c \
	$(RUN_COMMON) \
	-do "run -all"
	$(POST_RUN)

help:
	@printf  "\n\
	Available Commands:\n\
		all: build and run\n\
		build: compile code\n\
		run: simuate the code with QuestaSim in command line\n\
		gui: simulate the code QuestaSim GUI\n\
		clean: remove build files\n\
	Parameters:\n\
		TESTCASE <str>: name of uvm test\n\
			nominal: read values previously written to caches\n\
			evict: write to same index with different tag bits to force cache eviction\n\
			index: read/write to same block of data to ensure proper block indexing\n\
			mmio: read/write to memory mapped address space\n\
			random: random interleaving of previous test cases\n\
		VERBOSITY <str>: selects verbosity of print statments during testing\n\
			options: NONE, LOW, MEDIUM, HIGH, DEBUG\n\
				-> see readme.md for details on each level\n\
		SEED <int>: starter seed for uvm randomization\n\
		MEM_TIMEOUT <int>: allowed memory latency before timeout error\n\
		MEM_LATENCY <int>: cycles to wait before memory returns\n\
		ITERATIONS <int>: number of sub-sequences to run for a given test\n\
			setting iterations to 0 will make iterations random\n" | less

clean:
	rm -rf *.vstf work mitll90_Dec2019_all covhtmlreport *.log transcript *.wlf
