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

def compareTraces(sparce, spike):
	num_instr_skipped = len(spike) - len(sparce)
	# spike should have as many or less instructions than sparce
	assert(num_instr_skipped >= 0)
	
	sparce_idx = 0
	instr_skipped = [("PC", "Op Code(Literal)", "Op Code(Readable)")]
	for instr_spike in spike:
		if instr_spike[1] != sparce[sparce_idx][1]:
			instr_skipped.append(instr_spike)
		else: sparce_idx += 1
	print("")
	print("The sparce simulation skipped " + str(num_instr_skipped) + " instructions\n")
	print("These are the instructions that were skipped:\n")
	
	for instr in instr_skipped:
		print("%-20s %-20s %-20s" % instr)
	print("")
		
def fileToListOfTuples(file_path, spike=True):
	with open(file_path, "r") as f:
		if spike:
			return re.findall(INSTR_RE, f.read())[5:]
		else:
			return re.findall(INSTR_RE, f.read())

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
		compareTraces(sparce_instr_list, spike_instr_list)
	elif (args.spike_trace and args.sparce_trace):
		spike_instr_list = fileToListOfTuples(args.spike_trace)
		sparce_instr_list = fileToListOfTuples(args.sparce_trace, spike=False)
		compareTraces(sparce_instr_list, spike_instr_list)

      
