
import argparse
import sys
import glob
import subprocess
import os
import re
RISCV = '/home/asicfab/a/socet49/opt/riscv/bin/'

def compile_asm(filename):
    short_name = filename[:-2]
    output_name = short_name + '.elf'
    xlen = 'rv32imv'
    abi = 'ilp32'

    cmd_arr = [RISCV + 'riscv64-unknown-elf-gcc', '-march=' + xlen, '-mabi=' + abi,
                '-static', '-mcmodel=medany', '-fvisibility=hidden',
                '-nostdlib', '-nostartfiles', 
                '-T./verification/asm-env/link.ld',
                '-I./verification/asm-env/selfasm', filename, '-o',
                output_name]
    #print " ".join(cmd_arr)
    failure = subprocess.call(cmd_arr)
    if failure:
        return -1

    # create an meminit.hex file from the elf file produced above
    cmd_arr = ['/home/ecegrid/a/socpub/Public/riscv_dev/riscv_installs/RV_current/bin/elf2hex', '8', '65536', output_name, '2147483648']
    hex_file_loc = 'meminit.hex'
    with open(hex_file_loc, 'w') as hex_file:
        failure = subprocess.call(cmd_arr, stdout=hex_file)
    if failure:
        return -2
    else:
        return 0

def run(filename):
    ret = compile_asm(filename)
    if ret != 0:
        if ret == -1:
            print "An error has occured during GCC compilation"
        elif ret == -2:
            print "An error has occured converting elf to hex"
        sys.exit(ret)

    clean_init_hex(filename)

# Create a temp file that consists of the Intel HEX format
# version of the meminit.hex file, delete the original log file
# and rename the temp file to the original's name
def clean_init_hex(filename):
    init_output = 'meminit.hex'
    cleaned_location = init_output[:len(filename)-4] + "_clean.hex"
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
                addr_str = hex(addr/4)[2:]
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
    subprocess.call(['mv', cleaned_location, init_output])
    return


def calculate_checksum_str(data, addr):
    addr = addr/4
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

if __name__ == '__main__':
    run(sys.argv[1])
