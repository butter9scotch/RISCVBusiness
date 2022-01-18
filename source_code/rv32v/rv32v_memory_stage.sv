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
  rv32v_memory_writeback_if.memory memory_writeback_if,
  prv_pipeline_if.pipe prv_if
);
  import rv32i_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  logic [31:0] data0, wdat0, wdat1;

  address_scheduler_if asif ();

  address_scheduler AS (CLK, nRST, asif);


  assign hu_if.busy_mem = asif.busy;
  // assign hu_if.csr_update = (execute_memory_if.config_type) ? 1 : 0;
  assign hu_if.exception_mem = asif.exception;
  assign wdat0 = execute_memory_if.load ? data0 : execute_memory_if.aluresult0;
  assign wdat1 = execute_memory_if.load ? cif.dmemload : execute_memory_if.aluresult1;

  // To address scheduler
  assign asif.addr0      = execute_memory_if.aluresult0;
  assign asif.addr1      = execute_memory_if.aluresult1;
  assign asif.storedata0 = execute_memory_if.storedata0;
  assign asif.storedata1 = execute_memory_if.storedata1;
  //assign asif.sew        = memory_writeback_if.eew_loadstore; // TODO: From CSR
  assign asif.sew        = execute_memory_if.eew; // TODO: From CSR
  assign asif.eew_loadstore  = execute_memory_if.eew_loadstore; 
  assign asif.load       = execute_memory_if.load;
  assign asif.store      = execute_memory_if.store;
  assign asif.dhit       = cif.dhit;
  assign asif.returnex   = returnex;
  assign asif.woffset1   = execute_memory_if.woffset1;
  assign asif.vl         = execute_memory_if.vl;
  assign asif.ls_idx     = execute_memory_if.ls_idx;
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
      memory_writeback_if.wen[0]      <= '0;
      memory_writeback_if.wen[1]      <= '0;
      memory_writeback_if.woffset0  <= '0;
      memory_writeback_if.woffset1  <= '0;
      memory_writeback_if.rd_wen    <= '0;
      memory_writeback_if.rd_sel    <= '0;
      memory_writeback_if.rd_data   <= '0;

      memory_writeback_if.tb_line_num <= 0;


    end else if (hu_if.flush_mem) begin
      memory_writeback_if.wdat0     <= '0;
      memory_writeback_if.wdat1     <= '0;
      memory_writeback_if.wen[0]      <= '0;
      memory_writeback_if.wen[1]      <= '0;
      memory_writeback_if.woffset0  <= '0;
      memory_writeback_if.woffset1  <= '0;
      memory_writeback_if.rd_wen    <= '0;
      memory_writeback_if.rd_sel    <= '0;
      memory_writeback_if.rd_data   <= '0;

            //TESTBENCH ONLY
      memory_writeback_if.tb_line_num <= 0;

    end else if (!hu_if.stall_mem) begin
      memory_writeback_if.wdat0     <= wdat0;
      memory_writeback_if.wdat1     <= wdat1;
      memory_writeback_if.wen[0]      <= execute_memory_if.wen[0];
      memory_writeback_if.wen[1]      <= execute_memory_if.wen[1];
      memory_writeback_if.woffset0  <= execute_memory_if.woffset0;
      memory_writeback_if.woffset1  <= execute_memory_if.woffset1;

      memory_writeback_if.vd  <= execute_memory_if.vd;
      memory_writeback_if.eew <= execute_memory_if.eew;
      memory_writeback_if.vl  <= execute_memory_if.vl;
      memory_writeback_if.single_bit_write  <= execute_memory_if.single_bit_write;

      memory_writeback_if.rd_wen <= execute_memory_if.rd_wen;
      memory_writeback_if.rd_sel <= execute_memory_if.rd_sel;
      memory_writeback_if.rd_data <= ~(execute_memory_if.config_type == NOT_CFG) ? prv_if.rdata : execute_memory_if.rd_data;

      //TESTBENCH ONLY
      memory_writeback_if.tb_line_num <= execute_memory_if.tb_line_num;

      
    end
  end

  // CSR
  logic [31:0] vl, vlenb, vtype, vstart, next_vstart, next_vl, vlmax;
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      vl     <= '0;
      vlenb  <= '0;
      vtype  <= '0;
      vstart <= '0;
    end else if (execute_memory_if.config_type) begin
      vl     <= execute_memory_if.vl;
      vlenb  <= VLENB;
      vtype  <= execute_memory_if.next_vtype_csr;
      vstart <= '0;
    end else begin
      vstart <= next_vstart;
    end
  end
  assign memory_writeback_if.sew = sew_t'(vtype[2:0]);
  assign memory_writeback_if.mul  = vlmul_t'(vtype[5:3]);


  // VSTART_ADDR --> exception
  // VXSAT_ADDR --> who knows
  // VXRM_ADDR  --> who knows
  // VCSR_ADDR  --> who knows
  // VL_ADDR    --> will be set by config instrs
  // VTYPE_ADDR --> will be set by config instrs
  // VLENB_ADDR --> probably not use this
  logic [7:0] next_vl_csr;
  assign next_vl_csr = execute_memory_if.next_avl_csr[7:0]; //CHANGE FOR ACTUAL DECISION LOGIC
  assign prv_if.swap =  ~(execute_memory_if.config_type == NOT_CFG);
  assign prv_if.clr = 0;
  assign prv_if.set = 0;
  assign prv_if.wdata = {8'd0, next_vl_csr, execute_memory_if.next_vtype_csr};
  assign prv_if.addr = VTYPE_ADDR;
  assign prv_if.valid_write = prv_if.swap; 
  assign prv_if.instr = 0; 

  assign hu_if.csr_update =   ~(execute_memory_if.config_type == NOT_CFG);

  logic use_mem_pc;


  // Next vstart logic
/*
  always_comb begin
    if (asif.exception) next_vstart = asif.index;
    else if (success) next_vstart = 0;
    else next_vstart = vstart;
  end */

endmodule
