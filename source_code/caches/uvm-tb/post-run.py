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
#   Filename:     post-run.py
#
#   Created by:   Mitch Arndt
#   Email:        arndt20@purdue.edu
#   Date Created: 03/31/2022
#   Description:  Script for parsing test info from transcript after running tests

from datetime import datetime
import argparse

TESTCASE = None
SEED = None
ITERATIONS = None
MEM_TIMEOUT = None
MEM_LATENCY = None
MMIO_LATENCY = None

def parse_arguments():
    global TESTCASE, ITERATIONS, MEM_TIMEOUT, MEM_LATENCY, MMIO_LATENCY

    parser = argparse.ArgumentParser(description="Parse runtime parameters from the transcript for tracking purposes")
    parser.add_argument('testcase', metavar='testcase', type=str,
                        help="Specify the testcase")
    parser.add_argument('iterations', metavar='iterations', type=str,
                        help="Specify the requested number of memory accesses for a test")
    parser.add_argument('mem_timeout', metavar='mem_timeout', type=str,
                        help="Specify the max memory latency before a fatal timeout error")
    parser.add_argument('mem_latency', metavar='mem_latency', type=str,
                        help="Specify the number of clock cycles before memory returns")
    parser.add_argument('mmio_latency', metavar='mmio_latency', type=str,
                        help="Specify the number of clock cycles before memory mapped IO returns")
    args = parser.parse_args()
    TESTCASE = args.testcase
    ITERATIONS = args.iterations
    MEM_TIMEOUT = args.mem_timeout
    MEM_LATENCY = args.mem_latency
    MMIO_LATENCY = args.mmio_latency

class bcolors:
    LOG = '\033[95m[LOG]:'
    INFO = '\033[94m[INFO]:'
    SUCCESS = '\033[92m[SUCCESS]:'
    WARNING = '\033[93m[WARNING]:'
    FAIL = '\033[91m[FAIL]:'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def cprint(msg, *formats):
    for f in formats:
        print(f),
    print(msg),
    print(bcolors.ENDC)

keys = ["test", "seed", "iterations", "mem_timeout", "mem_latency", "mmio_latency", "d_cpu_txns", "i_cpu_txns", "mem_txns", "uvm_error", "uvm_fatal"] # keys to log variable

def display_log(log):
    for key in keys:
        try:
            if key == "uvm_error" or key == "uvm_fatal":
                num = int(log[key])
                if (num != 0):
                    cprint("{key}: {val}".format(key=key, val=log[key]), bcolors.FAIL)
                else:
                    cprint("{key}: {val}".format(key=key, val=log[key]), bcolors.SUCCESS)
                continue

            if "txns" in key:
                cprint("{key}: {val}".format(key=key, val=log[key]), bcolors.LOG)
                continue

            cprint("{key:<12}=> {val}".format(key=key, val=log[key]), bcolors.INFO)
        
        except:
            cprint("{key}: None".format(key=key), bcolors.FAIL)

def log2str(log):
    now = datetime.now()
    dt_string = now.strftime("%m-%d-%Y %H:%M:%S")
    
    out = "[{date}]: ".format(date=dt_string)

    for key in keys:
        try:
            out += "{key}: {val}, ".format(key=key, val=log[key])
        except:
            out += "{key}: None, ".format(key=key)
    
    return out


if __name__ == '__main__':
    cprint("Running Post Run Script...", bcolors.LOG)
    parse_arguments()

    log = {}
    log["test"] = TESTCASE
    log["iterations"] = ITERATIONS
    log["mem_timeout"] = MEM_TIMEOUT
    log["mem_latency"] = MEM_LATENCY
    log["mmio_latency"] = MMIO_LATENCY
    
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
                    if words[i-1] == "[I_CPU_SCORE]":
                        log["i_cpu_txns"] = words[i+1]
                    if words[i-1] == "[D_CPU_SCORE]":
                        log["d_cpu_txns"] = words[i+1]
                    elif words[i-1] == "[MEM_SCORE]":
                        log["mem_txns"] = words[i+1]
            if len(log) == len(keys):
                break # ignore the rest of the file

    display_log(log)
    
    with open("run_settings.log", "a") as out:
        out.write(log2str(log))
        out.write("\n")
        # print(log2str(log))

                        