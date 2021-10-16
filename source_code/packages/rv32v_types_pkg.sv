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
*   Filename:     rv32v_types_pkg.sv
*   
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/10/2021
*   Description:  Package containing types used for a RV32V implementation
*/

`ifndef RV32V_TYPES_PKG_SV
`define RV32V_TYPES_PKG_SV
// `include "rv32i_types_pkg.sv";

package rv32v_types_pkg;
  parameter VLEN_WIDTH = 7; // 128 bit registers
  parameter VL_WIDTH = VLEN_WIDTH; //width of largest vector = VLENB * 8 
  parameter VLEN = 1 << 7; 
  parameter VLENB = VLEN / 8; //VLEN in bytes
  parameter NUM_LANES = 2;


  typedef enum logic [2:0]  {
    SEW8    = 3'd0, 
    SEW16   = 3'd1,  
    SEW32   = 3'd2,
    SEW64   = 3'd3,
    SEW128  = 3'd4,
    SEW256  = 3'd5,
    SEW512  = 3'd6,
    SEW1024 = 3'd7
  } sew_t;

  typedef enum logic [2:0] {
    LMUL1       = 3'd0,
    LMUL2       = 3'd1,
    LMUL4       = 3'd2,
    LMUL8       = 3'd3,
    LMULHALF    = 3'd5,
    LMULFOURTH  = 3'd6,
    LMULEIGHTH  = 3'd7
  } vlmul_t;
  typedef logic [VLEN_WIDTH: 0] offset_t; //bits needed to hold offset

endpackage
`endif
