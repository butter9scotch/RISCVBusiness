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

TESTCASE = nominal_test
VERBOSITY = UVM_LOW
RAND_SEED = random

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
	+UVM_VERBOSITY=$(VERBOSITY) \
	-do "do $(WAVES)/wave.do" -do "run -all"

run:
	vsim -c tb_$(TOP) -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	-sv_seed $(RAND_SEED) \
	+UVM_TESTNAME=$(TESTCASE) \
	+UVM_VERBOSITY=$(VERBOSITY) \
	-do "run -all"

help:
	@printf  "\n\
	Available Commands:\n\
		all: build and run\n\
		build: compile code\n\
		run: simuate the code with QuestaSim in command line\n\
		gui: simulate the code QuestaSim GUI\n"

clean:
	rm -rf *.vstf work mitll90_Dec2019_all covhtmlreport *.log transcript *.wlf
