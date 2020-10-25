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
*   Filename:     template_execute.sv
*
*   Created by:   <author>
*   Email:        <author email>
*   Date Created: <date> 
*   Description:  This extension is the Template for creating rytpe custom
*                 instructions. 
*/

`include "risc_mgmt_execute_if.vh"

module rv32f_execute (
    input logic CLK, nRST,
    //risc mgmt connection
    risc_mgmt_execute_if.ext eif,
    //stage to stage connection
    input   rv32f_pkg::decode_execute_t idex,
    output  rv32f_pkg::execute_memory_t exmem
);
    import rv32f_pkg::*;

    assign eif.exception = 1'b0;
    assign eif.branch_jump = 1'b0;

    assign eif.busy = 1'b0;

    //should I write data now or later
    assign eif.reg_w = 1'b0;
    assign eif.reg_wdata = '0; //but we have three outputs(fpu_out, flags, and frm)
    assign exmem.funct7 = idex.funct7;
    assign exmem.load = idex.load;
    assign exmem.store = idex.store;
    assign exmem.rs1 = idex.rs2;
    assign exmem.rd = idex.rd;
    assign exmem.imm = idex.imm;
    assign exmem.frm = idex.frm;
    assign exmem.address = eif.rdata_s_0 + { {20{idex.imm[11]}}, idex.imm};

endmodule
