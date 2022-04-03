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
`include "rv32v_reorder_buffer_if.vh"

module rv32v_memory_stage (
  input logic CLK, nRST, returnex,
  cache_model_if.memory cif, // TODO: Remove/Change this during integration
  rv32v_hazard_unit_if.memory hu_if,
  rv32v_execute_memory_if.memory execute_memory_if,
  rv32v_memory_writeback_if.memory memory_writeback_if,
  prv_pipeline_if.pipe prv_if,
  rv32v_reorder_buffer_if.memory rob_if
);
  import rv32i_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  logic [31:0] data0, wdat0, wdat1, final_wdat0, final_wdat1;
  logic [5:0] addr0_shifted, addr1_shifted;

  address_scheduler_if asif ();

  address_scheduler AS (CLK, nRST, asif);


  assign hu_if.busy_mem = asif.busy;
  assign hu_if.memory_ena = execute_memory_if.ena;
  // assign hu_if.csr_update = (execute_memory_if.config_type) ? 1 : 0;
  assign addr0_shifted = asif.addr0[1:0] << 3;
  assign addr1_shifted = asif.addr1[1:0] << 3;
  assign hu_if.exception_mem = asif.exception;
  assign final_wdat0 = execute_memory_if.segment_type ? data0 >> addr0_shifted : // data0 / 8bit
                       data0; 
  assign final_wdat1 = execute_memory_if.segment_type ? cif.dmemload >> addr1_shifted :
                       cif.dmemload; 
  assign wdat0 = execute_memory_if.load_ena ? final_wdat0 : execute_memory_if.aluresult0;
  assign wdat1 = execute_memory_if.load_ena ? final_wdat1 : execute_memory_if.aluresult1;

  // To address scheduler
  assign asif.addr0      = execute_memory_if.aluresult0;
  assign asif.addr1      = execute_memory_if.aluresult1;
  assign asif.storedata0 = execute_memory_if.storedata0;
  assign asif.storedata1 = execute_memory_if.storedata1;
  //assign asif.sew        = memory_writeback_if.eew_loadstore; // TODO: From CSR
  assign asif.sew        = execute_memory_if.eew; // TODO: From CSR
  assign asif.eew_loadstore  = execute_memory_if.eew_loadstore; 
  assign asif.load_ena       = execute_memory_if.load_ena;
  assign asif.store_ena      = execute_memory_if.store_ena;
  assign asif.dhit       = cif.dhit;
  assign asif.returnex   = returnex;
  assign asif.woffset1   = execute_memory_if.woffset1;
  assign asif.vl         = execute_memory_if.vl;
  assign asif.ls_idx     = execute_memory_if.ls_idx;
  assign asif.segment_type  = execute_memory_if.segment_type;
  // To dcache
  assign cif.dmemstore = asif.final_storedata;
  assign cif.dmemaddr  = {asif.final_addr[31:2], 2'd0};
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

  rob_fu_result_t next_a_sigs, next_mu_sigs, next_du_sigs, next_m_sigs, next_p_sigs, next_ls_sigs;
    assign next_a_sigs.index = execute_memory_if.index;
    assign next_a_sigs.vl = execute_memory_if.vl;
    assign next_a_sigs.sew = execute_memory_if.eew;
    assign next_a_sigs.woffset = execute_memory_if.woffset0;
    assign next_a_sigs.exception_index = execute_memory_if.index;
    assign next_a_sigs.exception = 0;
    assign next_a_sigs.wdata = {wdat1, wdat0};
    assign next_a_sigs.vd = execute_memory_if.vd;
    assign next_a_sigs.wen = execute_memory_if.wen;
    assign next_a_sigs.ready = execute_memory_if.valid;
    //assign rob_if.counter_done = execute_memory_if.counter_done;

    assign next_mu_sigs = '0;
    assign next_du_sigs = '0;
    assign next_m_sigs = '0;
    assign next_p_sigs = '0;
    assign next_ls_sigs = '0;
    

  // Pipeline Latch
  always_ff @ (posedge CLK, negedge nRST) begin

    if (nRST == 0) begin
      memory_writeback_if.wdat0    <= '0;
      memory_writeback_if.wdat1    <= '0;
      memory_writeback_if.wen[0]   <= '0;
      memory_writeback_if.wen[1]   <= '0;
      memory_writeback_if.woffset0 <= '0;
      memory_writeback_if.woffset1 <= '0;
      memory_writeback_if.rd_wen   <= '0;
      memory_writeback_if.rd_sel   <= '0;
      memory_writeback_if.rd_data  <= '0;
      memory_writeback_if.ena      <= '0;
      memory_writeback_if.done     <= '0;

      rob_if.a_sigs       <= '0;
      rob_if.mu_sigs      <= '0;
      rob_if.du_sigs      <= '0;
      rob_if.m_sigs       <= '0;
      rob_if.p_sigs       <= '0;
      rob_if.ls_sigs      <= '0;
      rob_if.lmul         <= '0;
      rob_if.vl           <= '0;
      rob_if.counter_done <= '0;

    end else if (hu_if.flush_mem) begin
      memory_writeback_if.wdat0    <= '0;
      memory_writeback_if.wdat1    <= '0;
      memory_writeback_if.wen[0]   <= '0;
      memory_writeback_if.wen[1]   <= '0;
      memory_writeback_if.woffset0 <= '0;
      memory_writeback_if.woffset1 <= '0;
      memory_writeback_if.rd_wen   <= '0;
      memory_writeback_if.rd_sel   <= '0;
      memory_writeback_if.rd_data  <= '0;
      memory_writeback_if.ena      <= '0;
      memory_writeback_if.done     <= '0;

      rob_if.a_sigs       <= '0;
      rob_if.mu_sigs      <= '0;
      rob_if.du_sigs      <= '0;
      rob_if.m_sigs       <= '0;
      rob_if.p_sigs       <= '0;
      rob_if.ls_sigs      <= '0;
      rob_if.lmul         <= '0;
      rob_if.vl           <= '0;
      rob_if.counter_done <= '0;

    end else if (!hu_if.stall_mem) begin
      /*******************************************************
      *** To Scalar Unit
      *******************************************************/ 
      memory_writeback_if.rd_wen  <= execute_memory_if.rd_wen;
      memory_writeback_if.rd_sel  <= execute_memory_if.rd_sel;
      memory_writeback_if.rd_data <= execute_memory_if.rd_data;
      memory_writeback_if.ena     <= execute_memory_if.ena;
      memory_writeback_if.done    <= execute_memory_if.done;

      rob_if.a_sigs           <= next_a_sigs;
      rob_if.du_sigs          <= next_du_sigs;
      rob_if.m_sigs           <= next_m_sigs ;
      rob_if.mu_sigs          <= next_mu_sigs;
      rob_if.p_sigs           <= next_p_sigs ;
      rob_if.ls_sigs          <= next_ls_sigs;
      rob_if.single_bit_write <= memory_writeback_if.single_bit_write;
      rob_if.lmul             <= execute_memory_if.lmul;
      rob_if.vl               <= execute_memory_if.vl;
      rob_if.counter_done     <= execute_memory_if.counter_done;
    end
  end



endmodule
