/*
*   Copyright 2021 Purdue University
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
*   Filename:     vector_control_unit_if.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 10/13/2021
*   Description:  Interface for element counter
*                  
*/

`ifndef VECTOR_CONTROL_UNIT_IF_VH
`define VECTOR_CONTROL_UNIT_IF_VH
interface vector_control_unit_if();
  import alu_types_pkg::*;
  import rv32i_types_pkg::*;
  import rv32v_types_pkg::*;

  word_t instr;
  
  fu_t  fu_type; //which functional unit will be used
  athresult_t result_type;
  valuop_t aluop; 
  comp_t comp_type;
  mm_t minmax_type;
  ext_t ext_type;
  cfgsel_t cfgsel;
  // mm_t minmax_type;

  logic[4:0] SEW_f8;
  logic [1:0] eew;

  logic dwen, dren, wen; 
  opcode_t opcode; 
  logic [3:0] nf;
  mop_t [1:0] mop;
  logic vm;
  logic  [4:0] vs1, vs2, vd; //regfile sel lines
  // logic vs1_src; //choose between vd =1 and vs1 =0
  vs1_offset_src_t vs1_offset_src; 
  vs2_offset_src_t vs2_offset_src; //choose from diff offsets 
  vd_offset_src_t  vd_offset_src;
  logic imm_op; //imm op uses imm instead of vs1
  logic xs1_scalar_src, xs2_scalar_src, rd_scalar_src; //select signal to scalar regs
  logic arith_ena, mask_ena, perm_ena, reduction_ena, loadstore_ena, mul_ena, div_ena, fixed_point_ena; //unit enables
  width_t mem_op_width; //3 bit width field of load/store
  logic sign_extend; //sign extend the immediate value
  logic single_bit_op; //move this out to the decode stage top level?
  logic illegal_insn; 
  logic is_vload, is_vstore;
  logic de_en;
  logic stall;
  logic is_load, is_store;

  rs_t rs1_type;
  rs_t rs2_type;
  logic stride_type;
// TODO:
  logic is_signed; //op in the execution units is signed 
  logic ls_idx;
  // result_type,  multiply_type, multiply_pos_neg, reduction_ena, rev, mask, adc_sbc, carry_borrow_ena,  minmax_type, carryin_ena, win, zext_w, woutu, index,
  logic vd_widen;
  logic vs2_widen;
  logic [10:0] zimm_11; 
  logic [9:0] zimm_10;
  logic [4:0]  imm_5; 

  logic div_type;
  logic is_signed_div;
  logic high_low;
  logic [1:0] is_signed_mul;
  logic mul_widen_ena;
  logic multiply_pos_neg;
  logic multiply_type;

  logic adc_sbc;
  logic carry_borrow_ena;
  logic carryin_ena;
  logic rev;


  modport vcu (
    input instr,
    output dwen, dren, wen,
    aluop,
    opcode, 
    nf,
    mop,
    vm,
    eew,
    cfgsel,
    result_type,
    is_load,
    is_store,
    vs1, vs2, vd,  
    // vs1_src, 
    vs1_offset_src, vs2_offset_src,
    imm_op,
    xs1_scalar_src, xs2_scalar_src, rd_scalar_src,
    arith_ena, mask_ena, perm_ena, reduction_ena, loadstore_ena, mul_ena, div_ena, fixed_point_ena,
    fu_type,
    mem_op_width,
    sign_extend,
    is_signed, //
    single_bit_op,
    illegal_insn,
    vd_offset_src,
    de_en,
    stall,
    imm_5,
    zimm_11, 
    zimm_10,
    comp_type,
    minmax_type,
    ext_type,
    rs1_type,
    rs2_type,
    stride_type,
    vd_widen,
    vs2_widen,
    div_type,
    is_signed_div,
    high_low,
    is_signed_mul,
    mul_widen_ena,
    multiply_pos_neg,
    multiply_type,
    adc_sbc,
    carry_borrow_ena,
    carryin_ena,
    rev
  );




  
endinterface
`endif