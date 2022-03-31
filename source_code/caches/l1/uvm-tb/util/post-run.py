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

keys = ["test", "seed", "mem_timeout", "mem_latency", "mmio_latency", "uvm_error", "uvm_fatal"] # keys to log variable

def display_log(log):
    for key in keys:
        if key == "uvm_error" or key == "uvm_fatal":
            num = int(log[key])
            if (num != 0):
                cprint(key + ": " + log[key], bcolors.FAIL)
                continue
        
        cprint(key + ": " + log[key], bcolors.INFO)

def log2str(log):
    now = datetime.now()
    dt_string = now.strftime("%m-%d-%Y %H:%M:%S")
    
    out = "[{date}]: ".format(date=dt_string)

    for key in keys:
        out += "{key}: {val}, ".format(key=key, val=log[key])
    
    return out


if __name__ == '__main__':
    cprint("Running Post Run Script...", bcolors.LOG)

    log = {}
    
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

                if not log.has_key("testname") and "testname" in word.lower():
                    testcase = word.split("=")[1].replace("_test\"", "")
                    log["test"] = testcase

                if not log.has_key("mem_timeout") and "mem_timeout" in word.lower():
                    timeout = word.split(",")[2].replace("\"", "")
                    log["mem_timeout"] = timeout

                if not log.has_key("mem_latency") and "mem_latency" in word.lower():
                    lat = word.split(",")[2].replace("\"", "")
                    log["mem_latency"] = lat

                if not log.has_key("mmio_latency") and "mmio_latency" in word.lower():
                    lat = word.split(",")[2].replace("\"", "")
                    log["mmio_latency"] = lat

                if not log.has_key("uvm_fatal") and "UVM_FATAL" in word:
                    if (words[i+1] == ":"):
                        log["uvm_fatal"] = words[i+2]
                
                if not log.has_key("uvm_error") and "UVM_ERROR" in word:
                    if (words[i+1] == ":"):
                        log["uvm_error"] = words[i+2]
            if len(log) == len(keys):
                break # ignore the rest of the file

    display_log(log)
    
    with open("run_settings.log", "a") as out:
        out.write(log2str(log))
        out.write("\n")
        # print(log2str(log))

                        