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
*   Filename:     template_memory.sv
*
*   Created by:   <author>
*   Email:        <author email>
*   Date Created: <date> 
*   Description:  This extension is the Template for creating rytpe custom
*                 instructions
*/

`include "risc_mgmt_memory_if.vh"

module rv32f_memory (
    input logic CLK, nRST,
    //risc mgmt connection
    risc_mgmt_memory_if.ext mif,
    //stage to stage connection
    input rv32f_pkg::execute_memory_t exmem
);
    import rv32f_pkg::*;
    /*
    * Implementation note:
    *
    * For the AFTx06 tapeout, we did *not* want to work on coupling
    * the FPU tightly with the core. Since the FPU carries its own register
    * state however, we have the issue of feedback from the memory stage to the
    * execute stage, which RISC-MGMT does not readily provide for, for register
    * writeback in FLW instructions.
    *
    * We chose to embed the full FPU in the "memory" stage, since for the 2-stage
    * pipeline they are not actually in different stages; either way will incur
    * a stall in the same stage.
    *
    * In the future, this should be fixed such that the FP RFile is integrated into the
    * main pipeline, and enabled/disabled depending on which extensions are used.
    * The FPU, FP instruction decoding, etc. can be placed in the rv32f (and in future
    * rv32d) extension plugins. RISC-MGMT will need to be augmented with extra register
    * identifier bits that tag which register file it belongs to (i.e. a 6-bit scheme
    * where the lower 5 bits indicate which register, and the 6th bit selects FP vs. Int)
    *
    * This also requires splitting up the FPU and FRFile, removing the "FPU_all" wrapper
    */
    
    FPU_all fpu(
        .n_rst(nRST),
        .clk(CLK),
        .f_rd(idex.rd),
        .f_rs1(idex.rs1),
        .f_rs2(idex.rs2),
        .f_frm_in(idex.frm),
        .f_LW(idex.load),
        .f_SW(idex.store),
        .f_funct_7(idex.funct7),
        .fload_ext(eif.rdata_s_0),
        .FPU_all_out(fpu_result_temp),
        .f_flags(flags_result_temp),
        .f_frm_out(frm_result_temp)
    );



    assign mif.exception = 1'b0;
    assign mif.busy = 1'b0; //waiting for memory transaction?
    assign mif.reg_w = 1'b0;
    assign mif.reg_wdata = '0; //not needed
    always_comb begin
        if (mif.mem_busy == 1'b1) begin
            mif.mem_addr = '0;
            mif.mem_ren = 0;
            mif.mem_wen = 0;
            mif.mem_store = '0;
        end else begin
            if (decode_signals.load == 1'b1) begin
                mif.mem_addr = {27'b0, decode_signals.rd};
                mif.mem_store = exmem.fpu_result;
                mif.mem_ren = 1'b1;
            end else if (decode_signals.store == 1'b1) begin
                mif.mem_addr = {27'b0, decode_signals.rs2};
                mif.mem_store = exmem.fpu_result;
                mif.mem_wen = 1'b1;
            end else begin
                mif.mem_addr = {27'b0, decode_signals.rd};
                mif.mem_store = exmem.fpu_result;
                mif.mem_wen = 1'b1;
            end
        end
    end

endmodule
