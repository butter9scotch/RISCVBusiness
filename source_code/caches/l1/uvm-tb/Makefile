#RISCVBUSINESS PROJECT ROOT DIRECTORY
ROOT = ../../../..
TOP = caches_top
WAVES = scripts
CPU_AGENT = cpu_agent
MEM_AGENT = mem_agent
END2END = end2end
BUS_COMPS = generic_bus_components
ENV = env
SEQUENCES = sequences
TEST = tests
INCLUDE = $(ROOT)/source_code/include
PACKAGES = $(ROOT)/source_code/packages
SRC = $(ROOT)/source_code/caches/l1

TESTCASE = random_test
VERBOSITY = LOW
RAND_SEED = random

#env_config parameters
#TODO: THIS SHOULD PROBABLY BE 8, 4 for evict WB and 4 for read
MEM_TIMEOUT = 11

all: build run

gui: build run_gui

build: 
	vlog +incdir+$(SRC) \
	+incdir+$(INCLUDE) \
	+incdir+$(PACKAGES) \
	+incdir+$(CPU_AGENT) \
	+incdir+$(MEM_AGENT) \
	+incdir+$(END2END) \
	+incdir+$(BUS_COMPS) \
	+incdir+$(ENV) \
	+incdir+$(SEQUENCES) \
	+incdir+$(TEST) \
	+acc \
	+cover \
	-L $$QUESTA_HOME/uvm-1.2 tb_$(TOP).sv 

run_gui:
	vsim -i tb_$(TOP) -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	-sv_seed $(RAND_SEED) \
	+UVM_TESTNAME=$(TESTCASE) \
	+UVM_VERBOSITY=UVM_$(VERBOSITY) \
	+uvm_set_config_int=*,mem_timeout,$(MEM_TIMEOUT) \
	-do "do $(WAVES)/wave.do" -do "run -all"

run:
	vsim -c tb_$(TOP) -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	-sv_seed $(RAND_SEED) \
	+UVM_TESTNAME=$(TESTCASE) \
	+UVM_VERBOSITY=UVM_$(VERBOSITY) \
	+uvm_set_config_int=*,mem_timeout,$(MEM_TIMEOUT) \
	-do "run -all"

help:
	@printf  "\n\
	Available Commands:\n\
		all: build and run\n\
		build: compile code\n\
		run: simuate the code with QuestaSim in command line\n\
		gui: simulate the code QuestaSim GUI\n\
	Parameters:\n\
		TESTCASE: name of uvm test\n\
		VERBOSITY: NONE, LOW, MEDIUM, HIGH, DEBUG\n\
		RAND_SEED: starter seed for uvm randomization\n\
		MEM_TIMEOUT: allowed memory latency before timeout error\n"

clean:
	rm -rf *.vstf work mitll90_Dec2019_all covhtmlreport *.log transcript *.wlf
