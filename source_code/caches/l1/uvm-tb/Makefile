#RISCVBUSINESS PROJECT ROOT DIRECTORY
ROOT = ../../../..
TOP = l1_cache
WAVES = scripts
AGENT = agent
ENV = env
SEQUENCES = sequences
TEST = test
INCLUDE = $(ROOT)/source_code/include
PACKAGES = $(ROOT)/source_code/packages
SRC = $(ROOT)/source_code/caches/l1

TESTCASE = test

all: build run

build: 
	vlog +incdir+$(SRC) \
	+incdir+$(INCLUDE) \
	+incdir+$(PACKAGES) \
	+incdir+$(AGENT) \
	+incdir+$(ENV) \
	+incdir+$(SEQUENCES) \
	+incdir+$(TEST) \
	+acc \
	+cover \
	-L $$QUESTA_HOME/uvm-1.2 tb_$(TOP).sv 

run:
	vsim -i tb_$(TOP) -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME=$(TESTCASE) \
	+UVM_VERBOSITY=UVM_LOW \
	-do "do $(WAVES)/$(TOP).do" -do "run -all"

terminal_run: build terminal

terminal:
	vsim -c tb_$(TOP) -L \
	$$QUESTA_HOME/uvm-1.2 \
	-voptargs=+acc \
	-coverage \
	+UVM_TESTNAME=$(TESTCASE) \
	+UVM_VERBOSITY=UVM_LOW \
	-do "run -all"

help:
	@printf  "\n\
	Available Commands:\n\
		all: build and run\n\
		build: compile code\n\
		run: simuate the code with QuestaSim GUI\n\
		terminal: simulate the code with command line output only\n"

clean:
	rm -rf work
	rm -rf mitll90_Dec2019_all
	rm -rf covhtmlreport
	rm *.log
	rm transcript
	rm *.wlf
