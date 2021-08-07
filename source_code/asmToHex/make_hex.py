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
#   Filename:     run_tests.py
#
#   Created by:   Jacob R. Stevens
#   Email:        steven69@purdue.edu
#   Date Created: 06/01/2016
#   Description:  Script for running processor tests
import sys
import glob
import subprocess
import os
import re
def invert_bin_string(bin_string):
    inverted = ''
    while len(bin_string) < 8:
        bin_string = '0' + bin_string
    for bit in bin_string:
        if bit == '0':
            inverted = inverted + '1'
        else:
            inverted = inverted + '0'
    return inverted
# Returns the string representation of the
# checksum for the given data and address values
def calculate_checksum_str(data, addr):
    addr = addr//4
    high_addr = (addr & 0xFF00) >> 8
    low_addr = addr & 0x00FF
    data1 = data & 0x000000FF
    data2 = (data & 0x0000FF00) >> 8
    data3 = (data & 0x00FF0000) >> 16
    data4 = (data & 0xFF000000) >> 24
    checksum = 4 + high_addr + low_addr
    checksum += data1 + data2 + data3 + data4
    checksum = checksum & 0xFF
    checksum = int(invert_bin_string(bin(checksum)[2:]),2)
    checksum += 1
    checksum_lower_byte = hex(checksum)[2:]
    if len(checksum_lower_byte) > 2:
        checksum_lower_byte = checksum_lower_byte[-2:]
    return checksum_lower_byte 
# Create a temp file that consists of the Intel HEX format
# version of the meminit.hex file, delete the original log file
# and rename the temp file to the original's name
def clean_init_hex(file_name):
    init_output = 'meminit.hex'
    build_dir = './build/meminit.hex'
    cleaned_location = init_output[:len(file_name)-4] + "_clean.hex"
    addr = 0x00
    with open(init_output, 'r') as init_file:
        cleaned_file = open(cleaned_location, 'w')
        for line in init_file:
            stripped_line = line[:len(line)-1]
            for i in range(len(stripped_line), 0, -8):
                data_word = stripped_line[i-8:i]
                new_data_word = data_word[6:8] + data_word[4:6]
                new_data_word += data_word[2:4] + data_word[0:2]
                checksum = calculate_checksum_str(int(new_data_word, 16), addr)
                if len(checksum) < 2:
                    checksum = '0' + checksum
                addr_str = hex(addr//4)[2:]
                #left pad the string with 0s until 4 hex digits
                while len(addr_str) < 4:
                    addr_str = '0' + addr_str
                if new_data_word != "00000000":
                    out = ":04" + addr_str + "00" + new_data_word + checksum + '\n'
                    cleaned_file.write(out)
                addr += 0x4
        # add the EOL record to the file
        cleaned_file.write(":00000001FF")
        cleaned_file.close()
    subprocess.call(['rm', init_output])
    subprocess.call(['mv', cleaned_location, init_output])
    return

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: make_hex.py <ELF file name>")
        exit(1)
    with open("meminit.hex", "w") as fp:
        subprocess.run(["elf2hex", "4", "65536", sys.argv[1], "2147483648"], stdout=fp)


    clean_init_hex("test.hex")
