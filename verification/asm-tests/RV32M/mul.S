/*
*   Copyright 2016 Purdue University
*   
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*   
*       http://www.apache.org/licenses/LICENSE-2.0
*   
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*
*
*   Filename:     basic_branch.S
*
*   Created by:   Jacob R. Stevens
*   Email:        steven69@purdue.edu
*   Date Created: 07/01/2016
*   Description:  Test of basic branching behavior
*/


.section .text
.global _start

_start:
    li x1, 5
    li x2, 5
    mul x3, x1, x2
    la x6, tdat0
    sw x3, 0(x6)

    la      t1, tohost
    li      t2, 1
    sw      t2, 0(t1)




.section .tohost, "aw", @progbits
.globl tohost
.align 4
tohost: .dword 0
.globl fromhost
.align 4
fromhost: .dword 0
.data
#test data goes here
tdat0:  .word 0x00000080