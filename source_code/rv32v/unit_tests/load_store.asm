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
#   Filename: load_store.asm 
#   
#   Created By: Nicholas Gildenhuys
#   Email: ngildenh@purdue.edu
#   Date Created: Jan 26, 2022
#   Description: An assembly test for basic unit-stride load and store

# include "riscv_test.h"

RVTEST_DATA_DUMP_BEGIN

RVTEST_CODE_BEGIN
main:
  # primary intger instructions
  # load in the addresses to the vector data
  ori a0, x0, tdat0 
  ori a1, x0, sdat0
  ori a2, x0, rdat0
  # flush the pipeline with nops 
  nop
  nop
  nop
  nop
  nop
  nop
  nop
  # vector config instructions
  # a vector has an elemt width of 32, and a total length of 8 elements which 
  # means it spans 2 physical registers
  vsetivli t0, 8, e32, m2
  # configure the base address in the scalar register
  # load value from memory
  # vle32.v vd, (rs1), vm # 32 bit unit stride load 
  #vle32.v v4, (a0), vm # 32 bit unit stride load 
  vlw.v v4, (a0) # 32 bit unit stride load 
  #vle32.v v8, (a1), vm # 32 bit unit stride load 
  vlw.v v8, (a1) # 32 bit unit stride load 

  # modify the value
  vadd.vx v12, v4, v8

  # store the value back
  # vse32.v vs3, (rs1), vm # 32 bit unit stride store 
  vse32.v v12, (a2), vm # 32 bit unit stride load 

RVTEST_CODE_END

# test data
.data 
# vector 0
tdat0: .word 0x00000000 
tdat1: .word 0x00010001 
tdat2: .word 0x00020002
tdat3: .word 0x00030003
tdat5: .word 0x00040004
tdat5: .word 0x00050005
tdat6: .word 0x00060006
tdat7: .word 0x00070007

# vector 1
sdat0: .word 0x00000000 
sdat1: .word 0x00010001 
sdat2: .word 0x00020002
sdat3: .word 0x00030003
sdat5: .word 0x00040004
sdat5: .word 0x00050005
sdat6: .word 0x00060006
sdat7: .word 0x00070007

# resultant data
rdat0: .word 0x00000000

RVTEST_DATA_DUMP_END