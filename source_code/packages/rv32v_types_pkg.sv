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

  typedef enum logic [2:0] { 
    WIDTH8  = 3'd0, 
    WIDTH16 = 3'b101, 
    WIDTH32 = 3'b110
    // RES = 3'd1, 3'd2, 3'd3, 3'd4, 3'd7 
  } width_t;

  typedef enum logic [4:0] { 
    LUMOP_UNIT = 5'd0, 
    LUMOP_UNIT_FULLREG = 5'b01000, 
    LUMOP_UNIT_MASK = 5'b01011, //EEW 8
    LUMOP_UNIT_FAULT_ONLY = 5'b10000 //EEW 8
  } lumop_t;

  typedef enum logic [1:0] { 
    MOP_UNIT = 0,
    MOP_UINDEXED = 1,
    MOP_STRIDED = 2,
    MOP_OINDEXED = 3 
  } mop_t;

  typedef enum logic [2:0] { 
    ARITH,
    MASK,
    PERM,
    LOADSTORE,
    NOOP
  } funit_type;

  typedef enum logic [2:0] { 
    OPIVV = 3'b0,
    OPFVV = 3'd1,
    OPMVV = 3'd2,
    OPIVI = 3'd3,
    OPIVX = 3'd4,
    OPFVF = 3'd5,
    OPMVX = 3'd6,
    OPCFG = 3'd7
  } vfunct3;

  typedef enum logic [1:0] { 
    NOT_CFG, 
    VSETVLI,
    VSETIVLI,
    VSETVL 
  } cfgsel_t;

  typedef enum logic [5:0] {
    VADD = 6'b000000,
    VSUB = 6'b000010,
    VRSUB = 6'b000011,
    VMINU = 6'b000100,
    VMIN = 6'b000101,
    VMAXU = 6'b000110,
    VMAX = 6'b000111,
    VAND = 6'b001001,
    VOR = 6'b001010,
    VXOR = 6'b001011,
    VRGATHER = 6'b001100,
    VSLIDEUP = 6'b001110, //VRGATHEREI16 when OPIVV, something is very weird about this instruction
    VSLIDEDOWN = 6'b001111,
    VADC = 6'b010000,
    VMADC = 6'b010001,
    VSBC = 6'b010010,
    VMSBC = 6'b010011,
    VMERGE = 6'b010111,         //also VMV
    VMSEQ = 6'b011000,
    VMSNE = 6'b011001,
    VMSLTU = 6'b011010,
    VMSLT = 6'b011011,
    VMSLEU = 6'b011100,
    VMSLE = 6'b011101,
    VMSGTU = 6'b011110,
    VMSGT = 6'b011111,
    VMSADDU = 6'b100000,
    VMSADD = 6'b100001,
    VSSUBU = 6'b100010,
    VSSUB = 6'b100011,
    VSLL = 6'b100101,
    VSMUL = 6'b100111, //also VMV<nf>R
    VSRL = 6'b101000,
    VSRA = 6'b101001,
    VSSRL = 6'b101010,
    VSSRA = 6'b101011,
    VNSRL = 6'b101100,
    VNSRA = 6'b101101,
    VNCLIPU = 6'b101110,
    VNCLIP = 6'b101111,
    VWREDSUMU =6'b110000,
    VWREDSUM =6'b110001
  } vopi_t;

  typedef enum logic [5:0]{
    VREDSUM = 6'b000000,
    VREDAND = 6'b000001,
    VREDOR = 6'b000010,
    VREDXOR = 6'b000011,
    VREDMINU = 6'b000100,
    VREDMIN = 6'b000101,
    VREDMAXU = 6'b000110,
    VREDMAX = 6'b000111,
    VAADDU = 6'b001000,
    VAADD = 6'b001001,
    VASUBU = 6'b001010,
    VASUB = 6'b001011,
    VSLIDE1UP = 6'b001110,
    VSLIDE1DOWN = 6'b001111,
    VWXUNARY0 = 6'b010000, //V is w, X is VRXUNARY0
    VXUNARY0 = 6'b010010,
    VMUNARY0 = 6'b010100,
    VCOMPRESS = 6'b010111,
    VMANDNOT = 6'b011000,
    VMAND = 6'b011001,
    VMOR = 6'b011010,
    VMXOR = 6'b011011,
    VMORNOT = 6'b011100,
    VMNAND = 6'b011101,
    VMNOR = 6'b011110,
    VMXNOR = 6'b011111,
    VDIVU = 6'b100000,
    VDIV = 6'b100001,
    VREMU = 6'b100010,
    VREM = 6'b100011,
    VMULHU = 6'b100100,
    VMUL = 6'b100101,
    VMULHSU = 6'b100110,
    VMULH = 6'b100111,
    VMADD = 6'b101001,
    VNMSUB = 6'b101011,
    VMACC = 6'b101101,
    VNMSAC = 6'b101111,
    VWADDU = 6'b110000,
    VWADD = 6'b110001,
    VWSUBU = 6'b110010,
    VWSUB = 6'b110011,
    VWADDU_W = 6'b110100,
    VWADD_W = 6'b110101,
    VWSUBU_W = 6'b110110,
    VWSUB_W = 6'b110111,
    VWMULU = 6'b111000,
    VWMULSU = 6'b111010,
    VWMUL = 6'b111011,
    VWMACCU = 6'b111100,
    VWMACC = 6'b111101,
    VWMACCUS = 6'b111110,
    VWMACCSU = 6'b111111
  } vopm_t;

  

  typedef enum logic[4:0] { //vs1
    VMV_X_S = 5'b00000,
    VPOPC = 5'b10000,
    VFIRST = 5'b10001
  } vwxunary0_t;

  typedef enum logic[4:0] { 
    VMV_S_X = 5'b00000 
  } vrxunary0_t;

  typedef enum logic[4:0] { 
    VZEXT_VF8 = 5'b00010,
    VSEXT_VF8 = 5'b00011,
    VZEXT_VF4 = 5'b00100,
    VSEXT_VF4 = 5'b00101,
    VZEXT_VF2 = 5'b00110,
    VSEXT_VF2 = 5'b00111
  } vxunary0_t;

  typedef enum logic[4:0] { 
    VMSBF = 5'b00001,
    VMSOF = 5'b00010,
    VMSIF = 5'b00011,
    VIOTA = 5'b10000,
    VID = 5'b10001
  } vmunary0_t;

  typedef logic [VLEN_WIDTH: 0] offset_t; //bits needed to hold offset
  typedef logic [7:0] byte_t;
  typedef byte_t [VLENB-1:0]  vreg_t;
  
endpackage
`endif
