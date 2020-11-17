#!/usr/local/bin/python

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
#   Filename:     compare_trace.py
#
#   Created by:   James M. Zampa
#   Email:        jzampa@purdue.edu
#   Date Created: 10/13/2020
#   Description:  Compares traces between sparce simulation and spike simulation

import argparse 
import sys
import re
import subprocess

INSTR_RE = r'core[ ]+0: (0x[0-9a-f]+) \((0x[0-9a-f]+)\) ([a-z0-9 ,\(\)\+-]+)'
BYTE_RE = '[0-9a-f]+'
SASA_OFFSET_MASK = 0b11111
SASA_R1_MASK = 0b11111 << 11
SASA_R2_MASK = 0b11111 << 6
SASA_COND_MASK = 0b1 << 5

def compareTraces(sparce, spike, sasa_data):
	num_instr_skipped = 0
	sparce_idx = 0
	blocks_of_skips = []
	instr_skipped = []

	for instr_spike in spike:
		for entry in sasa_data:
			sasa_pc = int(entry[0], 16)
			sim_pc = int(sparce[sparce_idx][0][2:], 16)
			if (sasa_pc == sim_pc):
				instr_skipped.append(sparce[sparce_idx])

		if instr_spike[1] != sparce[sparce_idx][1]:
			instr_skipped.append(instr_spike)
		else: 
			sparce_idx += 1
			if (len(instr_skipped) > 1):
				num_instr_skipped += len(instr_skipped) - 1
				blocks_of_skips.append(instr_skipped)
				instr_skipped = []
	
	print("")
	print("The sparce simulation skipped " + str(num_instr_skipped) + " instructions in " + str(len(blocks_of_skips)) + " block(s)\n")
	
	for idx, code_block in enumerate(blocks_of_skips):
		print("Block %s:\n" % str(idx+1))
		print("Instruction responsible for skipping:\n")
		print("%-20s %-20s %-20s" % ("PC", "Op Code(Literal)", "Op Code(Readable)"))
		print("%-20s %-20s %-20s" % code_block[0])
		print("")
		print("Instructions skipped:\n")
		print("%-20s %-20s %-20s" % ("PC", "Op Code(Literal)", "Op Code(Readable)"))
		for instr in code_block[1:]:
			print("%-20s %-20s %-20s" % instr)
		print("")
		
def fileToListOfTuples(file_path, spike=True):
	with open(file_path, "r") as f:
		if spike:
			return re.findall(INSTR_RE, f.read())[5:]
		else:
			return re.findall(INSTR_RE, f.read())

def readSasaData(starting_mem_location):
	path_to_elf = './sim_out/RV32I/compare_traces/' + args.asm_file[:-2] + '.elf'
	cmd_arr = ['riscv64-unknown-elf-objdump', '-s', path_to_elf]
	failure = subprocess.Popen(cmd_arr, stdout=subprocess.PIPE)
	output = failure.stdout.read().decode("utf-8").split('\n')
	begin_load = False
	data_section = []
	hex_nums = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f']
	for line in output:
		if (line.startswith(starting_mem_location)):
			begin_load = True
		if (begin_load):
			if (line.startswith('Contents of section .riscv.attributes:')):
				break
			data_section.append(re.findall(BYTE_RE, line))
	sasa_data = []
	for mem_loc in data_section:
		for idx, bytes in enumerate(mem_loc[1:]):
			if (idx == 0) or (idx == 2):
				sasa_entry = []
			bytes = bytes[6] + bytes[7] + bytes[4] + bytes[5] + bytes[2] + bytes[3] + bytes[0] + bytes[1]
			sasa_entry.append(bytes)
			if (idx == 1) or (idx == 3):
				sasa_data.append(sasa_entry)
	end_of_sasa = 0;
	for idx, sasa_entry in enumerate(sasa_data):
		if (sasa_entry[0] == '00000000') and (sasa_entry[1] == '00000000'):
			end_of_sasa = idx
			break
	sasa_data = sasa_data[:end_of_sasa]
	readable_sasa_data = []
	for sasa_entry in sasa_data:
		readable_sasa_entry = [sasa_entry[0]]
		data_as_int = int(sasa_entry[1], 16)
		offset = data_as_int & SASA_OFFSET_MASK
		r1 = (data_as_int & SASA_R1_MASK) >> 11
		r2 = (data_as_int & SASA_R2_MASK) >> 6
		cond = (data_as_int & SASA_COND_MASK) >> 5
		readable_sasa_entry.append(r1)
		readable_sasa_entry.append(r2)
		if (cond):
			readable_sasa_entry.append('AND')
		else:
			readable_sasa_entry.append('OR')
		readable_sasa_entry.append(offset)
		readable_sasa_data.append(readable_sasa_entry)
	print("")
	print("SASA Table was loaded with the following:")
	print("")
	print("%-10s %-5s %-5s %-10s %-5s" % ('PC', 'R1', 'R2', 'Condition', 'Offset'))
	for sasa_entry in readable_sasa_data:
		print("%-10s %-5s %-5s %-10s %-5s" % (sasa_entry[0], sasa_entry[1], sasa_entry[2], sasa_entry[3], sasa_entry[4]))

	return readable_sasa_data
		

if __name__ == '__main__':
	description = 'Compare traces between sparce and spike simulations'
	parser = argparse.ArgumentParser(description=description)
	parser.add_argument('--assembly', '-s', dest='asm_file', type=str, default="",
							  help="Specify path to assmebly file")
	parser.add_argument('--sim', '-sim', dest='sparce_trace', type=str, default="",
							  help="Specify path to sparce trace file")
	parser.add_argument('--spike', '-spike', dest='spike_trace', type=str, default="",
							  help="Specify path to spike trace file")
	args = parser.parse_args()
   
	if (args.asm_file):
		cmd_arr = ['python', 'run_tests.py', '-t', 'compare', args.asm_file]
		failure = subprocess.call(cmd_arr, stdout=None)
		spike_instr_list = fileToListOfTuples(r'./sim_out/RV32I/compare_traces/' + args.asm_file[:-2] + '_spike.trace')
		sparce_instr_list = fileToListOfTuples(r'./sim_out/RV32I/compare_traces/' + args.asm_file[:-2] + '_sim.trace', spike=False)
		sasa_data = readSasaData(' 80001000')
		compareTraces(sparce_instr_list, spike_instr_list, sasa_data)
		
	elif (args.spike_trace and args.sparce_trace):
		spike_instr_list = fileToListOfTuples(args.spike_trace)
		sparce_instr_list = fileToListOfTuples(args.sparce_trace, spike=False)
		compareTraces(sparce_instr_list, spike_instr_list)

      
