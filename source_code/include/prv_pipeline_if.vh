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
*   Filename:     prv_pipeline_if.vh
*
*   Created by:   John Skubic
*   Email:        jskubic@purdue.edu
*   Date Created: 08/24/2016
*   Description:  Interface connecting the priv block to the pipeline.
*                 Contains connections between modules inside the priv block. 
*                 TODO: These two functionalities should be split into two
*                 separate interfaces.
*/

`ifndef PRV_PIPELINE_IF_VH
`define PRV_PIPELINE_IF_VH

interface prv_pipeline_if();

  import machine_mode_types_1_11_pkg::*;
  import rv32i_types_pkg::*;

  parameter NUM_EXTENSIONS = 2;

  logic insert_pc;
  logic intr;
  word_t priv_pc;
  logic pipe_clear;
  logic ret;
  logic fault_insn;
  logic mal_insn;
  logic illegal_insn;
  logic fault_l;
  logic mal_l;
  logic fault_s;
  logic mal_s;
  logic breakpoint;
  logic env_m;
  logic wb_enable;
  logic ex_rmgmt;
  logic [$clog2(NUM_EXTENSIONS)-1:0] ex_rmgmt_cause;
  word_t epc;
  word_t badaddr;
  logic invalid_csr;
  word_t rdata;
  csr_addr_t addr;
  logic swap;
  logic clr;
  logic set;
  logic valid_write;
  logic instr;
  word_t wdata;

  // vector extension signals
  logic vector_csr_instr;
  logic [2:0] lmul;
  logic [2:0] sew;
  logic vill;
  logic [VL_WIDTH:0] vl, vstart, vlenb; //[1, 128]
  logic [7:0] vtype;

  modport hazard (
    input insert_pc, intr, priv_pc, 
    output pipe_clear, ret, fault_insn, mal_insn, illegal_insn, fault_l, 
           mal_l, fault_s, mal_s, breakpoint, env_m, wb_enable, 
           ex_rmgmt, ex_rmgmt_cause, epc, badaddr
  );

  modport pipe (
    input invalid_csr, rdata, 
    output addr, swap, clr, set, valid_write,
           wdata, vector_csr_instr
  );

  modport vdecode (
    input vl, vstart, vlenb, vtype 
  );

  modport priv_block (
    input addr, pipe_clear, ret, fault_insn, mal_insn, illegal_insn, 
           fault_l, mal_l, fault_s, mal_s, breakpoint, env_m, 
           swap, clr, set, valid_write, wb_enable, instr, 
           ex_rmgmt, ex_rmgmt_cause, epc, badaddr, wdata, 
           vl, vstart, vlenb, vtype, vector_csr_instr,
    output insert_pc, intr, invalid_csr, priv_pc, rdata
  );

  modport cb (
    output instr
  );

endinterface

`endif //PRV_PIPELINE_IF_VH
