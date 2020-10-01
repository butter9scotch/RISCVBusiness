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

module fpu_memory (
  input logic CLK, nRST,
  //risc mgmt connection
  risc_mgmt_memory_if.ext mif,
  //stage to stage connection
  input fpu_pkg::execute_memory_t exmem
);
  import fpu_pkg::*;
  decode_execute_t decode_signals;

  //prevent this extension from accessing the core
  //memory data vs register data??
  assign mif.exception = 1'b0;
  assign mif.busy = 1'b0; //waiting for memory transaction??
  assign mif.reg_w = 1;b0;
  always_comb begin
    if (mif.mem_busy == 1'b1) begin
      mif.mem_addr = '0;
      mif.mem_ren = 0;
      mif.mem_wen = 0;
      mif.mem_store = '0; //
      mif.reg_wdata = '0; //
    end else begin
      if (decode_signals.load == 1'b1) begin
        mif.mem_addr = decode_signals.rd;
        mif.mem_ren = 1'b1;///////?
      end else if (decode_signals.store == 1'b1) begin
        mif.mem_addr = decode_signals.rs2;
        mif.mem_wen = 1'b1;/////?
      end else begin
        mif.mem_addr = decode_signals.rd;
        mif.mem_wen = 1'b1;/////?
      end
    end
  end

endmodule
