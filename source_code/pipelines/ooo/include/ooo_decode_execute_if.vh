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
*   Filename:     tspp_fetch_execute_if.vh
*   
*   Created by:   Jacob R. Stevens	
*   Email:        steven69@purdue.edu
*   Date Created: 06/01/2016
*   Description:  Interface between the fetch and execute pipeline stages
*/

`ifndef OOO_DECODE_EXECUTE_IF_VH
`define OOO_DECODE_EXECUTE_IF_VH

interface ooo_decode_execute_if();

  import rv32i_types_pkg::*;
  import rv32m_pkg::*;
  import alu_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  word_t port_a; //
  word_t port_b; //
  word_t reg_file_wdata; //
  scalar_fu_t sfu_type; //
  logic halt_instr; //


  // new structs for the interface
  exception_control_signals_t exception_sigs; //
  csr_control_signals_t csr_sigs; //
  arith_control_signals_t arith_sigs; //
  jump_control_signals_t jump_sigs; //
  branch_control_signals_t branch_sigs; // 
  mult_control_signals_t mult_sigs; //
  div_control_signals_t div_sigs; //
  lsu_constrol_signals_t lsu_sigs; //
  cpu_tracker_signals_t tracker_sigs; //

  modport decode (
    output port_a, port_b, reg_file_wdata, sfu_type, halt_instr,
    exception_sigs, csr_sigs,
    arith_sigs, jump_sigs, branch_sigs, 
    mult_sigs,
    div_sigs,
    lsu_sigs,
    tracker_sigs 
  );

  modport execute (
    input port_a, port_b, reg_file_wdata, sfu_type, halt_instr,
    exception_sigs, csr_sigs,
    arith_sigs, jump_sigs, branch_sigs, 
    mult_sigs,
    div_sigs,
    lsu_sigs,
    tracker_sigs 
  );

endinterface

`endif //OOO_DECODE_EXECUTE_IF_VH
