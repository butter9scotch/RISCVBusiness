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


main:
  li x1, 0x5
  li x2, 0x3
  li x3, 0x3
  li x4, 0x3
  nop
  nop
  nop
  nop
  nop
  nop
label:
  j label
.data
#test data goes here
tdat0:  .word 0x00000080
