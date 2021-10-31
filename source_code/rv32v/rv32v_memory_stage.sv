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
*   Filename:     rv32v_memory_stage.sv
*
*   Created by:   Jing Yin See
*   Email:        see4@purdue.edu
*   Date Created: 10/30/2021
*   Description:  RV32V Memory Stage
*/

`include "rv32v_execute_memory_if.vh"
`include "rv32v_memory_writeback_if.vh"
`include "cache_model_if.vh"
`include "address_scheduler_if.vh"

module rv32v_memory_stage (
  input logic CLK, nRST, returnex,
  cache_model_if.memory cif, // TODO: Remove/Change this during integration
  rv32v_hazard_unit_if.memory hu_if,
  rv32v_execute_memory_if.memory execute_memory_if,
  rv32v_memory_writeback_if.memory memory_writeback_if
);
  import rv32v_types_pkg::*;

  logic [31:0] data0, wdat0, wdat1;

  address_scheduler_if asif ();

  address_scheduler AS (CLK, nRST, asif);

  assign hu_if.busy_mem = asif.busy;
  assign hu_if.csr_update = execute_memory_if.config_type;
  assign hu_if.exception_mem = asif.exception;
  assign wdat0 = execute_memory_if.load ? data0 : execute_memory_if.aluresult0;
  assign wdat1 = execute_memory_if.load ? cif.dmemload : execute_memory_if.aluresult1;

  // To address scheduler
  assign asif.addr0      = execute_memory_if.aluresult0;
  assign asif.addr1      = execute_memory_if.aluresult1;
  assign asif.storedata0 = execute_memory_if.storedata0;
  assign asif.storedata1 = execute_memory_if.storedata1;
  assign asif.sew        = memory_writeback_if.sew; // TODO: From CSR
  assign asif.load       = execute_memory_if.load;
  assign asif.store      = execute_memory_if.store;
  assign asif.dhit       = cif.dhit;
  assign asif.returnex   = returnex;
  // To dcache
  assign cif.dmemstore = asif.final_storedata;
  assign cif.dmemaddr  = asif.final_addr;
  assign cif.ren       = asif.ren;
  assign cif.wen       = asif.wen;
  assign cif.byte_ena  = asif.byte_ena;

  // Load buffer
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      data0 <= '0;
    end else if (asif.arrived0) begin
      data0 <= cif.dmemload;
    end
  end

  // Pipeline Latch
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      memory_writeback_if.wdat0     <= '0;
      memory_writeback_if.wdat1     <= '0;
      memory_writeback_if.wen0      <= '0;
      memory_writeback_if.wen1      <= '0;
      memory_writeback_if.woffset0  <= '0;
      memory_writeback_if.woffset1  <= '0;
    end else if (hu_if.flush_mem) begin
      memory_writeback_if.wdat0     <= '0;
      memory_writeback_if.wdat1     <= '0;
      memory_writeback_if.wen0      <= '0;
      memory_writeback_if.wen1      <= '0;
      memory_writeback_if.woffset0  <= '0;
      memory_writeback_if.woffset1  <= '0;
    end else if (!hu_if.stall_mem) begin
      memory_writeback_if.wdat0     <= wdat0;
      memory_writeback_if.wdat1     <= wdat1;
      memory_writeback_if.wen0      <= execute_memory_if.wen0;
      memory_writeback_if.wen1      <= execute_memory_if.wen1;
      memory_writeback_if.woffset0  <= execute_memory_if.woffset0;
      memory_writeback_if.woffset1  <= execute_memory_if.woffset1;
    end
  end

  // CSR
  logic [31:0] vl, vlenb, vtype, vstart, next_vstart, next_vl, vlmax;
  logic vma, vta, vill;
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      vl     <= '0;
      vlenb  <= '0;
      vtype  <= '0;
      vstart <= '0;
    end else if (execute_memory_if.config_type) begin
      vl     <= execute_memory_if.vl;
      vlenb  <= VLENB;
      vtype  <= execute_memory_if.vtype;
      vstart <= '0;
    end else begin
      vstart <= next_vstart;
    end
  end
  assign memory_writeback_if.sew = sew_t'(vtype[2:0]);
  assign memory_writeback_if.lmul  = vlmul_t'(vtype[5:3]);
  assign vta   = vtype[6];
  assign vma   = vtype[7];
  assign vill  = vtype[7];
  // Next vstart logic
/*
  always_comb begin
    if (asif.exception) next_vstart = asif.index;
    else if (success) next_vstart = 0;
    else next_vstart = vstart;
  end */

endmodule
