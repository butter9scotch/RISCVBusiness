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
#   Description:  Script for configuring and running UVM TB for the caches

import argparse
from scripts.cprint import cprint
from scripts.cprint import bcolors
from scripts.build import build
from scripts.run import run
from scripts.post_run import post_run

def seed_type(arg):
    try:
        return int(arg)  # try convert to int
    except ValueError:
        pass
    if arg == "random":
        return arg
    raise argparse.ArgumentTypeError("Seed must be an integer type or 'random'")

def parse_arguments():
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
    return parser.parse_args()


if __name__ == '__main__':
    params = parse_arguments()

    if params.clean:
        cprint("Cleaning Directory...", bcolors.LOG)
        os.system("rm -rf *.vstf work mitll90_Dec2019_all covhtmlreport *.log transcript *.wlf coverage/*.ucdb **/*.pyc")
        exit()

    build(params)

    if (params.build):
        exit() # stop after build

    run(params)

    cprint("Running Post Run Script...", bcolors.LOG)

    # print parameters
    skip = ["verbosity", "gui", "clean", "seed", "build"]
    for arg in vars(params):
        if arg in skip:
            continue #skip showing in info
        cprint("{key:<15}<- {val}".format(key=arg, val=getattr(params, arg)), bcolors.INFO)

    post_run(params)
                        