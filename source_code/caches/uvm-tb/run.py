#!/usr/bin/python

#
#   Copyright 2016 Purdue University
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
#
#   Filename:     run.py
#
#   Created by:   Mitch Arndt
#   Email:        arndt20@purdue.edu
#   Date Created: 04/04/2022
#   Description:  Script for running UVM TB for the caches

import os
from datetime import datetime
import argparse

params = None

class bcolors:
    LOG         = '\033[95m[{:<7}]:'.format("LOG")
    INFO        = '\033[94m[{:<7}]:'.format("INFO")
    SUCCESS     = '\033[92m[{:<7}]:'.format("SUCCESS")
    WARNING     = '\033[93m[{:<7}]:'.format("WARNING")
    FAIL        = '\033[91m[{:<7}]:'.format("FAIL")
    ENDC        = '\033[0m'
    BOLD        = '\033[1m'
    UNDERLINE   = '\033[4m'

def cprint(msg, *formats):
    for f in formats:
        print(f),
    print(msg),
    print(bcolors.ENDC)

def seed_type(arg):
    try:
        return int(arg)  # try convert to int
    except ValueError:
        pass
    if arg == "random":
        return arg
    raise argparse.ArgumentTypeError("Seed must be an integer type or 'random'")

def parse_arguments():
    global params
    parser = argparse.ArgumentParser(formatter_class=argparse.RawTextHelpFormatter,
                        description="\033[95m\033[1mBuild and Run the UVM Testbench for the cache hierarchy\n"
                                    "  Note that all runtime parameters are saved in \033[4mrun_summary.log\033[0m")
    parser.add_argument('--clean', action="store_true",
                        help="Remove build artifacts")
    parser.add_argument('--build', action="store_true",
                        help="Build project without run")
    parser.add_argument('--testcase', '-t', type=str, default="random",
                        choices=["nominal", "evict", "index", "mmio", "random"],
                        help="Specify name of the uvm test:\n"
                        "  nominal:   read back values previously written to caches\n"
			            "  evict:     write to same index with different tag bits to force cache eviction\n"
			            "  index:     read/write to same block of data to ensure proper block indexing\n"
			            "  mmio:      read/write to memory mapped address space\n"
			            "  random:    random interleaving of previous test cases")
    parser.add_argument('--gui', '-g', action='store_true',
                        help="Specify whether to run with gui or terminal only")
    parser.add_argument('--verbosity', '-v', type=str, default="low",
                        choices=["none", "low", "medium", "high", "full", "debug"],
                        help="Specify the verbosity level to be used for UVM Logging, each stage builds on the next\n"
                        "  none:  - only error messages shown\n"
                        "  low:   - actual and expected values for scoreboard errors\n"
                        "         - success msg for data matches\n"
                        "         - sequence parameters\n"
                        "  medium - actual and expected values for all scoreboard checks\n"
                        "         - predictor default values for non-initialized memory\n"
                        "         - end2end transaction/propagation details\n"
                        "  high   - all uvm transactions detected in monitors, predictors, scoreboards\n"
                        "         - predictor memory before:after\n"
                        "  full   - all connections between analysis ports\n"
                        "         - all agent sub-object instantiations\n"
                        "         - all virtual interface accesses to uvm db\n"
                        "  debug  - all messages")
    parser.add_argument('--seed', '-s', type=seed_type, default="random",
                        help="Specify starter seed for uvm randomization\n"
                        "Identical seeds will produce identical runs")
    parser.add_argument('--iterations', '-i', type=int, default=0,
                        help="Specify the requested number of memory accesses for a test")
    parser.add_argument('--mem_timeout', type=int, default=50,
                        help="Specify the max memory latency before a fatal timeout error")
    parser.add_argument('--mem_latency', type=int, default=1,
                        help="Specify the number of clock cycles before main memory returns")
    parser.add_argument('--mmio_latency', type=int, default=2,
                        help="Specify the number of clock cycles before memory mapped IO returns")
    parser.add_argument('--config', type=str, default="full",
                        choices=["l1", "l2", "full"],
                        help="Specify the configuration of the testbench to determine which agents and modules are activated")

    args = parser.parse_args()
    params = args #set global variable

def build():
    cprint("Building Sources...", bcolors.LOG)
    SRC = "../../../source_code/"

    if params.config == "l1":
        TB_GLOBAL_CONFIG = "TB_L1_CONFIG"
    elif params.config == "l2":
        TB_GLOBAL_CONFIG = "TB_L2_CONFIG"
    elif params.config == "full":
        TB_GLOBAL_CONFIG = "TB_FULL_CONFIG"
    else:
        cprint("Invalid testbench configuration: {}".format(params.config), bcolors.FAIL)
        exit()

    res = os.system('''\
        vlog\
        +incdir+{CACHES} \
	    +incdir+{L1} \
	    +incdir+{L2} \
	    +incdir+{INCLUDE} \
	    +incdir+{PACKAGES} \
	    +incdir+models \
	    +incdir+cpu_agent \
	    +incdir+bus_agents \
	    +incdir+end2end \
	    +incdir+generic_bus_agent_comps \
	    +incdir+bfm \
	    +incdir+env \
	    +incdir+sequences \
	    +incdir+tests \
	    +define+TB_{TB_GLOBAL_CONFIG}_CONFIG \
	    +acc \
	    +cover \
	    -L {QUESTA_HOME}/uvm-1.2 tb_caches_top.sv 
    '''.format(
        CACHES=SRC + "caches",
        L1=SRC + "caches/l1",
        L2=SRC + "caches/l2",
        INCLUDE=SRC + "include",
        PACKAGES=SRC + "packages",
        QUESTA_HOME=os.getenv('QUESTA_HOME'),
        TB_GLOBAL_CONFIG=params.config.upper()
    ))

    if (res == 0):
        cprint("Build Finished", bcolors.SUCCESS)
    else:
        cprint("Build Failed", bcolors.FAIL)
        exit()

def run():
    RUN_COMMON = '''
        tb_caches_top -L
	    {QUESTA_HOME}/uvm-1.2
	    -voptargs=+acc
	    -sv_seed {SEED}
	    +UVM_TESTNAME={TESTCASE}_test
	    +UVM_VERBOSITY=UVM_{VERBOSITY}
	    +uvm_set_config_int=*,iterations,{ITERATIONS}
	    +uvm_set_config_int=*,mem_timeout,{MEM_TIMEOUT}
	    +uvm_set_config_int=*,mem_latency,{MEM_LATENCY}
	    +uvm_set_config_int=*,mmio_latency,{MMIO_LATENCY}
	    -do "coverage save -onexit -p coverage/{TESTCASE}.ucdb"
    '''.format(
        QUESTA_HOME=os.getenv('QUESTA_HOME'),
        SEED=params.seed,
        TESTCASE=params.testcase,
        VERBOSITY=params.verbosity.upper(),
        ITERATIONS=params.iterations,
        MEM_TIMEOUT=params.mem_timeout,
        MEM_LATENCY=params.mem_latency,
        MMIO_LATENCY=params.mmio_latency,
    )

    if (params.gui):
        cprint("Running with GUI...", bcolors.LOG)
        res = os.system('''
            vsim -i
            {RUN_COMMON}
            -do "do scripts/{WAVE}.do"
	        -do "run -all"
        '''.format(
            RUN_COMMON=RUN_COMMON,
            WAVE=params.config
        ).replace("\n", " "))
    else: 
        cprint("Running with Terminal...", bcolors.LOG)
        res = os.system('''
            vsim -c
            {RUN_COMMON}
	        -do "run -all"
        '''.format(
            RUN_COMMON=RUN_COMMON,
        ).replace("\n", " "))

    if (res == 0):
        cprint("Run Finished", bcolors.SUCCESS)
    else:
        cprint("Run Failed", bcolors.FAIL)

def post_run():
    if params.config == "l1":
        keys = ["seed", "cpu_txns", "mem_txns", "uvm_error", "uvm_fatal"] # keys to log variable
    elif params.config == "l2":
        keys = ["seed", "mem_arb_txns", "mem_txns", "uvm_error", "uvm_fatal"] # keys to log variable
    elif params.config == "full":
        keys = ["seed", "d_cpu_txns", "i_cpu_txns", "mem_txns", "uvm_error", "uvm_fatal"] # keys to log variable

    log = {}
    if (params.seed != "random"):
        log["seed"] = params.seed

    with open("transcript", "r") as transcript:
        lines = transcript.readlines()
        for line in lines:
            words = line.strip().split()
            for i, word in enumerate(words):
                if not log.has_key("seed") and "seed" in word.lower():
                    if words[i+1] == "=":
                        log["seed"] = words[i+2]
                    elif words[i+1] != "random":
                        log["seed"] = words[i+1]

                if not log.has_key("uvm_fatal") and "UVM_FATAL" in word:
                    if (words[i+1] == ":"):
                        log["uvm_fatal"] = words[i+2]
                
                if not log.has_key("uvm_error") and "UVM_ERROR" in word:
                    if (words[i+1] == ":"):
                        log["uvm_error"] = words[i+2]

                if "TXN_Total" in word:
                    if words[i-1] == "[MEM_SCORE]":
                        log["mem_txns"] = words[i+1]
                    elif words[i-1] == "[I_CPU_SCORE]":
                        log["i_cpu_txns"] = words[i+1]
                    elif words[i-1] == "[D_CPU_SCORE]":
                        log["d_cpu_txns"] = words[i+1]
                    elif words[i-1] == "[CPU_SCORE]":
                        log["cpu_txns"] = words[i+1]
                    elif words[i-1] == "[MEM_ARB_SCORE]":
                        log["mem_arb_txns"] = words[i+1]
                
                if len(log) == len(keys):
                    break # ignore the rest of the file

    for key in keys:
        try:
            if key == "uvm_error" or key == "uvm_fatal":
                num = int(log[key])
                if (num != 0):
                    cprint("{key:<15}-> {val}".format(key=key, val=log[key]), bcolors.FAIL)
                else:
                    cprint("{key:<15}-> {val}".format(key=key, val=log[key]), bcolors.SUCCESS)
                continue

            cprint("{key:<15}-> {val}".format(key=key, val=log[key]), bcolors.SUCCESS)
        
        except:
            cprint("{key:<15}-> {val}".format(key=key, val="None"), bcolors.FAIL)
    
    with open("run_summary.log", "a") as out:
        now = datetime.now()
        dt_string = now.strftime("%m-%d-%Y %H:%M:%S")
        
        msg = "[{date}]: ".format(date=dt_string)

        msg += "test: {}, ".format(params.testcase)
        msg += "seed: {}, ".format(log["seed"])
        msg += "config: {}, ".format(params.config)
        msg += "iterations: {}, ".format(params.iterations)
        msg += "mem_timeout: {}, ".format(params.mem_timeout)
        msg += "mem_latency: {}, ".format(params.mem_latency)
        msg += "mmio_latency: {}, ".format(params.mmio_latency)

        for key in keys:
            if key == "seed": 
                continue
            try:
                msg += "{key}: {val}, ".format(key=key, val=log[key])
            except:
                msg += "{key}: None, ".format(key=key)
        
        out.write(msg)
        out.write("\n")


if __name__ == '__main__':
    # os.system('vlog')
    parse_arguments()

    if params.clean:
        cprint("Cleaning Directory...", bcolors.LOG)
        os.system("rm -rf *.vstf work mitll90_Dec2019_all covhtmlreport *.log transcript *.wlf coverage/*.ucdb")
        exit()

    build()

    if (params.build):
        exit() # stop after build

    run()

    cprint("Running Post Run Script...", bcolors.LOG)

    # print parameters
    skip = ["verbosity", "gui", "clean", "seed", "build"]
    for arg in vars(params):
        if arg in skip:
            continue #skip showing in info
        cprint("{key:<15}<- {val}".format(key=arg, val=getattr(params, arg)), bcolors.INFO)

    post_run()
                        