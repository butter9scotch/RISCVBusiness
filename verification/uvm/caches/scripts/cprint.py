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
#   Filename:     cprint.py
#
#   Created by:   Mitch Arndt
#   Email:        arndt20@purdue.edu
#   Date Created: 04/16/2022
#   Description:  Script for colored printing to terminal

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