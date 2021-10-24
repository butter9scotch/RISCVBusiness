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
*   Filename:     control_unit.sv
*
*   Created by:   Owen Prince
*   Email:        oprince@purdue.edu
*   Date Created: 10/13/2021
*   Description:  Control signals for vector extension
*                  
*/

`include "control_unit_if.vh"
`include "rv32i_reg_file_if.vh"
`include "risc_mgmt_if.vh"
`include "decompressor_if.vh"
`include "component_selection_defines.vh"
`include "vector_control_unit_if.vh"

module vector_control_unit 
(
  vector_control_unit_if.vcu  vcu_if
  //rv32i_reg_file_if.cu          rf_if
  //input logic [4:0] rmgmt_rsel_s_0, rmgmt_rsel_s_1, rmgmt_rsel_d,
  //input logic rmgmt_req_reg_r, rmgmt_req_reg_w 
);
  import alu_types_pkg::*;
  import rv32i_types_pkg::*;
  import rv32v_types_pkg::*;
  import machine_mode_types_1_11_pkg::*;

  rtype_t instr_r;
  itype_t instr_i;
  lumop_t lumop;
  cfgsel_t cfgsel;
  logic reduction_ena;
  vfunct3_t vfunct3;
  vop_decoded_t op_decoded;
  

  assign instr_r   = rtype_t'(vcu_if.instr);
  assign instr_i   = itype_t'(vcu_if.instr);

  assign vcu_if.opcode       = opcode_t'(vcu_if.instr[6:0]);
  assign vcu_if.vs1          = vcu_if.instr[19:15];
  assign vcu_if.vs2          = vcu_if.instr[24:20];
  assign vcu_if.vd           = vcu_if.instr[11:7]; 
  
  //load/store stuff
  assign vcu_if.mem_op_width = width_t'(instr_r.funct3);
  assign vcu_if.nf           = vcu_if.instr[31:29];
  assign vcu_if.mop          = mop_t'(vcu_if.instr[27:26]);
  assign vcu_if.vm           = vcu_if.instr[25];
  assign lumop               = lumop_t'(vcu_if.instr[24:20]);
  assign funct6_opi          = vopi_t'(vcu_if.instr[31:20]);
  assign funct6_opm          = vopm_t'(vcu_if.instr[31:20]);  
  assign vfunct3             = vfunct3_t'(instr_r.funct3);

  

  // Assign the immediate values
  assign imm_5   = vcu_if.instr[19:15];
  assign zimm_11 = vcu_if.instr[30:20];
  assign zimm_10 = vcu_if.instr[29:20];

  //intermediary variables 
  assign is_vload  = (vcu_if.opcode == STORE_FP) && ((vcu_if.mem_op_width == WIDTH8) || (vcu_if.mem_op_width == WIDTH16) || (vcu_if.mem_op_width == WIDTH32));
  assign is_vstore = (vcu_if.opcode == LOAD_FP)  && ((vcu_if.mem_op_width == WIDTH8) || (vcu_if.mem_op_width == WIDTH16) || (vcu_if.mem_op_width == WIDTH32));

  //Use OPI vs OPM enum
  assign is_vopi   = (vcu_if.opcode == VECTOR)  && (( vfunct3 == OPIVV) || (vfunct3 == OPIVX) || (vfunct3 == OPIVI));
  assign is_vopm   = (vcu_if.opcode == VECTOR)  && ( (vfunct3 == OPMVV) || (vfunct3 == OPMVX));

  //config instructions
  assign vcu_if.cfgsel = (vcu_if.opcode == VECTOR) && (vfunct3 == OPCFG) && (vcu_if.instr[31] == 0) ? VSETVLI : 
                         (vcu_if.opcode == VECTOR) && (vfunct3 == OPCFG) && (vcu_if.instr[31:30] == 2'b11) ? VSETIVLI : 
                         (vcu_if.opcode == VECTOR) && (vfunct3 == OPCFG) && (vcu_if.instr[31:30] == 2'b10) ? VSETVL  : NOT_CFG;

  
  // Assign memory read/write enables
  assign vcu_if.dwen = is_vload;
  assign vcu_if.dren = is_vstore;


  //enable counter
  assign vcu_if.de_en = is_vload | is_vstore | (vcu_if.opcode == VECTOR);
  always_comb begin
    
  if (is_vopi) begin
    case (funct6_opi)
      VADD:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VADD : vop_decoded_t'(0)  ;
      VSUB:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSUB : vop_decoded_t'(0);
      VRSUB:  	  op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VRSUB : vop_decoded_t'(0);
      VMINU:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMINU : vop_decoded_t'(0);
      VMIN:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMIN : vop_decoded_t'(0);
      VMAXU:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMAXU : vop_decoded_t'(0);
      VMAX:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMAX : vop_decoded_t'(0);
      VAND:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VAND : vop_decoded_t'(0);
      VOR:        op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VOR : vop_decoded_t'(0);
      VXOR:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VXOR : vop_decoded_t'(0);
      VRGATHER:   op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VRGATHER : vop_decoded_t'(0);
      VSLIDEUP:   op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSLIDEUP : (vfunct3 == OPIVV) ? OP_VRGATHEREI16 : vop_decoded_t'(0);
      VSLIDEDOWN: op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSLIDEDOWN : vop_decoded_t'(0);
      VADC:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VADC : vop_decoded_t'(0);
      VMADC:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMADC : vop_decoded_t'(0);
      VSBC:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSBC : vop_decoded_t'(0);
      VMSBC:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMSBC : vop_decoded_t'(0);
      VMERGE:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) && vcu_if.vm == vop_decoded_t'(0) ? OP_VMERGE : (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) && vcu_if.vm == vop_decoded_t'(0) ? OP_VMV : vop_decoded_t'(0);
      VMSEQ:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSEQ : vop_decoded_t'(0);
      VMSNE:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSNE : vop_decoded_t'(0);
      VMSLTU:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMSLTU : vop_decoded_t'(0);
      VMSLT:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMSLT : vop_decoded_t'(0);
      VMSLEU:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSLEU : vop_decoded_t'(0);
      VMSLE:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSLE : vop_decoded_t'(0);
      VMSGTU: 	  op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSGTU : vop_decoded_t'(0);
      VMSGT: 	    op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSGT : vop_decoded_t'(0);
      VSADDU:    op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSADDU : vop_decoded_t'(0);
      VSADD:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSADD : vop_decoded_t'(0);
      VSSUBU:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSSUBU : vop_decoded_t'(0);
      VSSUB:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSSUB : vop_decoded_t'(0);
      VSLL:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSLL : vop_decoded_t'(0);
      VSMUL:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSMUL : vop_decoded_t'(0);
      VSRL:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSRL : vop_decoded_t'(0);
      VSRA:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSRA : vop_decoded_t'(0);
      VSSRL:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSSRL : vop_decoded_t'(0);
      VSSRA:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSSRA : vop_decoded_t'(0);
      VNSRL:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VNSRL : vop_decoded_t'(0);
      VNSRA:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VNSRA : vop_decoded_t'(0);
      VNCLIPU:    op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VNCLIPU : vop_decoded_t'(0);
      VNCLIP:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VNCLIP : vop_decoded_t'(0);
      VWREDSUMU:  op_decoded = (vfunct3 == OPIVV) ? 	OP_VWREDSUMU : vop_decoded_t'(0);
      VWREDSUM:   op_decoded = (vfunct3 == OPIVV) ? OP_VWREDSUM : vop_decoded_t'(0);
    endcase
  end else if (is_vopm) begin
    case (funct6_opm)
      VREDSUM:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDSUM   : vop_decoded_t'(0);
      VREDAND:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDAND   : vop_decoded_t'(0);
      VREDOR:       op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDOR    : vop_decoded_t'(0);
      VREDXOR:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDXOR   : vop_decoded_t'(0);
      VREDMINU:     op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDMINU    : vop_decoded_t'(0);
      VREDMIN:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDMIN   : vop_decoded_t'(0);
      VREDMAXU:     op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDMAXU    : vop_decoded_t'(0);
      VREDMAX:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDMAX   : vop_decoded_t'(0);
      VAADDU:       op_decoded = (vfunct3 == OPMVV) ||	(vfunct3 == OPMVX) ? OP_VAADDU   : vop_decoded_t'(0);
      VAADD:        op_decoded = (vfunct3 == OPMVV) ||	(vfunct3 == OPMVX) ? OP_VAADD    : vop_decoded_t'(0);
      VASUBU:       op_decoded = (vfunct3 == OPMVV) ||	(vfunct3 == OPMVX) ? OP_VASUBU   : vop_decoded_t'(0);
      VASUB:        op_decoded = (vfunct3 == OPMVV) ||	(vfunct3 == OPMVX) ? OP_VASUB    : vop_decoded_t'(0);
      VSLIDE1UP:    op_decoded = (vfunct3 == OPMVX) ? OP_VSLIDE1UP   : vop_decoded_t'(0);
      VSLIDE1DOWN:  op_decoded = (vfunct3 == OPMVX) ? OP_VSLIDE1DOWN   : vop_decoded_t'(0);
      VWXUNARY0:    begin op_decoded =  (vfunct3 == OPMVV) && (vcu_if.vs1 == VMV_X_S) ? OP_VMV_X_S : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VPOPC)   ? OP_VPOPC : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VFIRST)  ? OP_VFIRST :
                                        (vfunct3 == OPMVX) && (vcu_if.vs2 == VMV_S_X) ? OP_VMV_S_X : vop_decoded_t'(0);
                    end 
      VXUNARY0:     begin op_decoded =  (vfunct3 == OPMVV) && (vcu_if.vs1 == VZEXT_VF8) ?  OP_VZEXT_VF8 : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VSEXT_VF8) ?  OP_VSEXT_VF8 : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VZEXT_VF4) ?  OP_VZEXT_VF4 : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VSEXT_VF4) ?  OP_VSEXT_VF4 : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VZEXT_VF2) ?  OP_VZEXT_VF2 : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VSEXT_VF2) ?  OP_VSEXT_VF2 : vop_decoded_t'(0);
                    end 
      VMUNARY0:     begin op_decoded =  (vfunct3 == OPMVV) && (vcu_if.vs1 == VMSBF) ? OP_VMSBF : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VMSOF) ? OP_VMSOF : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VMSIF) ? OP_VMSIF : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VIOTA) ? OP_VIOTA : 
                                        (vfunct3 == OPMVV) && (vcu_if.vs1 == VID)   ? OP_VID   : vop_decoded_t'(0);
                    end 
      VCOMPRESS:    op_decoded = (vfunct3 == OPMVV)                       ? OP_VCOMPRESS : vop_decoded_t'(0);
      VMANDNOT:     op_decoded = (vfunct3 == OPMVV)                       ? OP_VMANDNOT : vop_decoded_t'(0);
      VMAND:        op_decoded = (vfunct3 == OPMVV)                       ? OP_VMAND : vop_decoded_t'(0);
      VMOR:         op_decoded = (vfunct3 == OPMVV)                       ? OP_VMOR : vop_decoded_t'(0);
      VMXOR:        op_decoded = (vfunct3 == OPMVV)                       ? OP_VMXOR : vop_decoded_t'(0);
      VMORNOT:      op_decoded = (vfunct3 == OPMVV)                       ? OP_VMORNOT : vop_decoded_t'(0);
      VMNAND:       op_decoded = (vfunct3 == OPMVV)                       ? OP_VMNAND : vop_decoded_t'(0);
      VMNOR:        op_decoded = (vfunct3 == OPMVV)                       ? OP_VMNOR : vop_decoded_t'(0);
      VMXNOR:       op_decoded = (vfunct3 == OPMVV)                       ? OP_VMXNOR : vop_decoded_t'(0);
      VDIVU:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VDIVU : vop_decoded_t'(0);
      VDIV:         op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VDIV : vop_decoded_t'(0);
      VREMU:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VREMU : vop_decoded_t'(0);
      VREM:         op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VREM : vop_decoded_t'(0);
      VMULHU:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMULHU : vop_decoded_t'(0);
      VMUL:         op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMUL : vop_decoded_t'(0);
      VMULHSU:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMULHSU : vop_decoded_t'(0);
      VMULH:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMULH : vop_decoded_t'(0);
      VMADD:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMADD : vop_decoded_t'(0);
      VNMSUB:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VNMSUB : vop_decoded_t'(0);
      VMACC:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMACC : vop_decoded_t'(0);
      VNMSAC:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VNMSAC : vop_decoded_t'(0);
      VWADDU:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWADDU : vop_decoded_t'(0);
      VWADD:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWADD : vop_decoded_t'(0);
      VWSUBU:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWSUBU : vop_decoded_t'(0);
      VWSUB:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWSUB : vop_decoded_t'(0);
      VWADDU_W:     op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWADDU_W : vop_decoded_t'(0);
      VWADD_W:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWADD_W : vop_decoded_t'(0);
      VWSUBU_W:     op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWSUBU_W : vop_decoded_t'(0);
      VWSUB_W:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWSUB_W : vop_decoded_t'(0);
      VWMULU:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMULU : vop_decoded_t'(0);
      VWMULSU:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMULSU : vop_decoded_t'(0);
      VWMUL:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMUL : vop_decoded_t'(0);
      VWMACCU:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMACCU : vop_decoded_t'(0);
      VWMACC:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMACC : vop_decoded_t'(0);
      VWMACCUS:     op_decoded = (vfunct3 == OPMVX)                       ? OP_VWMACCUS : vop_decoded_t'(0);
      VWMACCSU:     op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMACCSU : vop_decoded_t'(0);
    endcase
  end else begin
    vcu_if.illegal_insn = 1;
  end
  end



  //vs1 source
  assign vcu_if.vs1_src = is_vstore; //stores use vs3 == vd for reading the data that will be stored

  
  assign vcu_if.imm_op = ((vfunct3 == OPCFG) || (vfunct3 == OPIVI)) && (vcu_if.opcode == VECTOR); 
  
  //use rs1, rs1, rd. when VMV_X_S, VMV_X_S, VFIRST write to rd
  assign vcu_if.rs1_scalar_src = is_vstore || is_vload || (cfgsel == VSETVLI) || (cfgsel == VSETIVLI) || (cfgsel == VSETVL) || (vcu_if.opcode == OPIVX) || (vcu_if.opcode == OPFVF) || (vcu_if.opcode == OPMVX);
  
  assign vcu_if.rs2_scalar_src = (is_vstore || is_vload) && (vcu_if.mop == MOP_STRIDED);
  assign vcu_if.rd_scalar_src = ((vfunct3 == OPCFG) || 
                                  ((funct6_opi == VWXUNARY0) && 
                                  ((vcu_if.vs1  == VMV_X_S) || (vcu_if.vs1  == VMV_X_S) || (vcu_if.vs1  == VFIRST)))) && 
                                  (vcu_if.opcode == VECTOR); 
  always_comb begin
    vcu_if.arith_ena = 0;
    vcu_if.reduction_ena = 0;
    vcu_if.mul_ena = 0;
    vcu_if.div_ena = 0;
    vcu_if.mask_ena = 0;
    vcu_if.perm_ena = 0;
    vcu_if.fixed_point_ena = 0;
    case (op_decoded)
      OP_VADD, OP_VSUB, OP_VRSUB, OP_VMINU, OP_VMIN, OP_VMAXU, OP_VMAX, OP_VAND, OP_VOR, OP_VXOR, OP_VADC, OP_VMADC, 
      OP_VSBC, OP_VMSBC, OP_VMERGE, OP_VMERGE, OP_VMSEQ, OP_VMSNE, OP_VMSLTU, OP_VMSLT, OP_VMSLEU, OP_VMSLE, OP_VMSGTU, 
      OP_VMSGT, OP_VSRL, OP_VSRA, OP_VNSRL, OP_VNSRA, OP_VZEXT_VF8, OP_VSEXT_VF8, OP_VZEXT_VF4, OP_VSEXT_VF4, 
      OP_VZEXT_VF2, OP_VSEXT_VF2, OP_VMADD, OP_VNMSUB, OP_VMACC, OP_VNMSAC, OP_VWADDU, OP_VWADD, OP_VWSUBU, OP_VWSUB, OP_VWADDU_W, 
      OP_VWADD_W, OP_VWSUBU_W, OP_VWSUB_W, OP_VWMACCU, OP_VWMACC, OP_VWMACCUS, OP_VWMACCSU: vcu_if.arith_ena = 1;
      OP_VWREDSUMU, OP_VWREDSUM, OP_VREDSUM, OP_VREDAND, OP_VREDOR, OP_VREDXOR, OP_VREDMINU, OP_VREDMIN, OP_VREDMAXU, VREDMAX: vcu_if.reduction_ena = 1;
      OP_VREM, OP_VMULHU, OP_VMUL, OP_VMULHSU, OP_VMULH, OP_VWMULU, OP_VWMULSU, VWMUL: vcu_if.mul_ena = 1;
      OP_VDIVU, OP_VDIV, OP_VREMU, VREM: vcu_if.div_ena = 1;
      OP_VPOPC, OP_VFIRST, OP_VMSBF, OP_VMSOF, OP_VMSIF, OP_VIOTA, OP_VID, OP_VMANDNOT, OP_VMAND, OP_VMOR, OP_VMXOR, OP_VMORNOT, OP_VMNAND, OP_VMNOR, VMXNOR: vcu_if.mask_ena = 1;
      OP_VRGATHER, OP_VSLIDEUP, OP_VRGATHEREI16, OP_VSLIDEDOWN, OP_VSLIDE1UP, OP_VSLIDE1DOWN, OP_VMV_X_S, OP_VMV_S_X, VCOMPRESS: vcu_if.perm_ena = 1;
      OP_VSADDU, OP_VSADD, OP_VSSUBU, OP_VSSUB, OP_VSMUL, OP_VSSRL, OP_VSSRA, OP_VNCLIPU, OP_VNCLIP, OP_VAADDU, OP_VAADD, OP_VASUBU, VASUB: vcu_if.fixed_point_ena = 1;
    endcase
  end
  assign vcu_if.loadstore_ena = is_vload | is_vstore; 
    

  //select mask unit
  assign vcu_if.fu_type = vcu_if.arith_ena ? ARITH :
                              vcu_if.mask_ena  ? MASK :
                              vcu_if.perm_ena  ? PEM :
                              is_vload ? LOAD_UNIT : 
                              is_vstore ? STORE_UNIT : ARITH; 

  //sign_extend uimm           
  assign vcu_if.is_signed  = ~((funct6_opi == VSLL) || (funct6_opi == VSRL)|| (funct6_opi == VSRA)|| (funct6_opi == VNSRL)|| (funct6_opi == VNSRA)|| 
                              (funct6_opi == VSSRL)|| (funct6_opi == VSSRA)|| (funct6_opi == VNCLIPU)|| (funct6_opi == VNCLIP)|| (funct6_opi == VSLIDEUP)||
                                 (funct6_opi == VSLIDEDOWN)|| (funct6_opi == VRGATHER) || (vcu_if.cfgsel == VSETIVLI)); //vmv1r includes vmv2, vmv4, vmv8

  //write to 1 bit instead of 1 element
  assign vcu_if.single_bit_op  = (funct6_opi == VMSEQ) || (funct6_opi == VMSNE) || (funct6_opi == VMSLTU) || (funct6_opi == VMSLT) || (funct6_opi == VMSLEU) || 
                                  (funct6_opi == VMSLE) || (funct6_opi == VMSGTU) || (funct6_opi == VMSGT);


  // Assign register write enable

  always_comb begin
    case(vcu_if.opcode)
      LOAD_FP: vcu_if.wen   = 1'b1;
      VECTOR:  vcu_if.wen = is_vopi || is_vopm;
      STORE_FP: vcu_if.wen   = 1'b0;
      default:  vcu_if.wen   = 1'b0;
    endcase
  end

  //stall
  assign vcu_if.stall = ((vfunct3 == OPIVV) && (funct6_opi == VSLIDEUP)) || ((funct6_opi == VRGATHER) && is_vopi);

  //choose vs1 offset, 
  assign vcu_if.vs1_offset_src = (vfunct3 == OPMVV) && (op_decoded inside {OP_VREDSUM, OP_VREDAND, OP_VREDOR, OP_VREDXOR, OP_VREDMINU, OP_VREDMIN, OP_VREDMAXU, OP_VREDMAX}) ; //some reduction ops
  
  always_comb begin
    vcu_if.vs2_offset_src = 0;
    case(funct6_opi)
      VSLIDEDOWN: begin 
        if  (vfunct3 == OPIVX) vcu_if.vs2_offset_src = 1; // i + rs1; 
        else if (vfunct3 == OPIVI) vcu_if.vs2_offset_src = 2; //i +uimm 
        else if (vfunct3 == OPMVX) vcu_if.vs2_offset_src = 3; //i +uimm --> this turns into slide1down 
      end
      VRGATHER: begin
        if (vfunct3 == OPIVV) vcu_if.vs2_offset_src = 4; // vs1[i]
        else if (vfunct3 == OPIVX) vcu_if.vs2_offset_src = 5; // x[rs1]
        else if (vfunct3 == OPIVI) vcu_if.vs2_offset_src = 6; // uimm
      end
      VSLIDEUP: if (vfunct3 == OPIVV) vcu_if.vs2_offset_src = 4; // vs1[i]
      default:  vcu_if.vs2_offset_src = 0;
    endcase

    if ((funct6_opm == VWXUNARY0) && (vwxunary0_t'(vcu_if.vs1) == VMV_X_S)) begin
      vcu_if.vs2_offset_src = 1; //vs2[0]
    end


  end


  // vcu_if.vd_offset_src  = if reduction, scalar move s.x, choose 0; if slideup vx choose i + rs1; if slideup vi choose i + uimm; if slide1up choose i + 1; if compress then use permutation vd; if else i; 
  always_comb begin
    vcu_if.vd_offset_src = 0; //i
    if (reduction_ena) begin 
      vcu_if.vd_offset_src = 1; //0
    end else if (is_vopi) begin
      case  (funct6_opi)
        VSLIDEUP:  begin
            if (vfunct3 == OPIVX) vcu_if.vd_offset_src = 2; // i + rs1
            else if (vfunct3 == OPIVI) vcu_if.vd_offset_src = 3; // i + uimm
            else if (vfunct3 == OPMVX) vcu_if.vd_offset_src = 4; // i + 1
          end
        VCOMPRESS: vcu_if.vd_offset_src = 5; //use special counter
      endcase
    end
  end


  // Assign alu opcode
  // logic sr, aluop_srl, aluop_sra, aluop_add, aluop_sub, aluop_and, aluop_or;
  // logic aluop_sll, aluop_xor, aluop_slt, aluop_sltu, add_sub;
 
  always_comb begin
    case(op_decoded)
      OP_VADD, OP_VSUB, OP_VRSUB, OP_VMINU, OP_VMIN, OP_VMAXU, OP_VMAX, OP_VAND, OP_VOR, OP_VXOR, OP_VRGATHER, 
      OP_VSLIDEUP, OP_VRGATHEREI16, OP_VSLIDEDOWN, OP_VADC, OP_VSBC, OP_VMERGE, OP_VMV, OP_VMSEQ, OP_VMSNE, 
      OP_VMSLTU, OP_VMSLT, OP_VMSLEU, OP_VMSLE, OP_VMSGTU, OP_VMSGT, OP_VSADDU, OP_VSADD, OP_VSSUBU, OP_VSSUB, OP_VSLL, 
      OP_VSRL, OP_VSRA, OP_VSSRL, OP_VSSRA, OP_VNSRL, OP_VNSRA, OP_VNCLIPU, OP_VNCLIP, OP_VWREDSUMU, OP_VWREDSUM, 
      OP_VREDSUM, OP_VREDAND, OP_VREDOR, OP_VREDXOR, OP_VREDMINU, OP_VREDMIN, OP_VREDMAXU, OP_VREDMAX, OP_VAADDU, OP_VAADD, 
      OP_VASUBU, OP_VASUB, OP_VSLIDE1UP, OP_VSLIDE1DOWN, OP_VMV_X_S, OP_VPOPC, OP_VFIRST, OP_VMV_S_X, OP_VZEXT_VF8, 
      OP_VSEXT_VF8, OP_VZEXT_VF4, OP_VSEXT_VF4, OP_VZEXT_VF2, OP_VSEXT_VF2, OP_VMSBF, OP_VMSOF, OP_VMSIF, OP_VIOTA, OP_VID, 
      OP_VCOMPRESS, OP_VMANDNOT, OP_VMAND, OP_VMOR, OP_VMXOR, OP_VMORNOT, OP_VMNAND, OP_VMNOR, OP_VMXNOR, OP_VWADDU, OP_VWADD, OP_VWSUBU, 
      OP_VWSUB, OP_VWADDU_W, OP_VWADD_W, OP_VWSUBU_W, OP_VWSUB_W:  vcu_if.result_type =    NORMAL; 
      OP_VMADC, OP_VMSBC: vcu_if.result_type = A_S; 
      OP_VSMUL, OP_VMULHU, OP_VMUL, OP_VMULHSU, OP_VMULH, OP_VWMULU, OP_VWMULSU, OP_VWMUL: vcu_if.result_type = MULTI;
      OP_VDIVU, OP_VDIV: vcu_if.result_type = DIVI;
      OP_VREMU, OP_VREM: vcu_if.result_type = REM;
      default: vcu_if.result_type = A_S;
    endcase
  end

  always_comb begin
    case(op_decoded)
      OP_VSLL: vcu_if.aluop = VALU_SLL;
      OP_VSRL, OP_VSSRL, OP_VNSRL: vcu_if.aluop = VALU_SRL;
      OP_VSRA, OP_VSSRA, OP_VNSRA: vcu_if.aluop = VALU_SRA;
      OP_VADD, OP_VADC, OP_VMADC, OP_VSADDU, OP_VSADD, OP_VWREDSUMU, OP_VWREDSUM, OP_VREDSUM, OP_VAADDU, OP_VAADD, OP_VWADDU, OP_VWADD, OP_VWADDU_W, OP_VWADD_W: vcu_if.aluop = VALU_ADD;
      OP_VSUB, OP_VRSUB, OP_VSBC, OP_VMSBC, OP_VSSUBU, OP_VSSUB, OP_VASUBU, OP_VASUB, OP_VWSUBU, OP_VWSUB, OP_VWSUBU_W, OP_VWSUB_W: vcu_if.aluop = VALU_SUB;       
      OP_VAND, OP_VREDAND, OP_VMANDNOT, OP_VMAND, OP_VMNAND: vcu_if.aluop = VALU_AND;
      OP_VOR, OP_VREDOR, OP_VMOR, OP_VMORNOT, OP_VMNOR:     vcu_if.aluop = VALU_OR;
      OP_VXOR, OP_VREDXOR, OP_VMXOR, OP_VMXNOR: vcu_if.aluop = VALU_XOR;
      OP_VMSEQ, OP_VMSNE, OP_VMSLTU, OP_VMSLT, OP_VMSLEU, OP_VMSLE, OP_VMSGTU, OP_VMSGT: vcu_if.aluop = VALU_COMP;    
      OP_VMERGE: vcu_if.aluop = VALU_MERGE;
      OP_VMV, OP_VMV_X_S, OP_VMV_S_X: vcu_if.aluop = VALU_MOVE;
      OP_VMINU, OP_VMIN, OP_VMAXU, OP_VMAX, OP_VREDMINU, OP_VREDMIN, OP_VREDMAXU, OP_VREDMAX: vcu_if.aluop = VALU_MM;
      OP_VZEXT_VF8, OP_VSEXT_VF8, OP_VZEXT_VF4, OP_VSEXT_VF4, OP_VZEXT_VF2, OP_VSEXT_VF2, OP_VMSBF, OP_VMSOF, OP_VMSIF, OP_VIOTA, OP_VID:   vcu_if.aluop = VALU_EXT;
      default: vcu_if.aluop = VALU_SLL;
    endcase
  end

  always_comb begin
    case(op_decoded)
      OP_VMSEQ:	 vcu_if.comp_type = VSEQ;
      OP_VMSNE:  vcu_if.comp_type = VSNE;
      OP_VMSLTU: vcu_if.comp_type = VSLTU;
      OP_VMSLT:  vcu_if.comp_type = VSLT;
      OP_VMSLEU: vcu_if.comp_type = VSLEU;
      OP_VMSLE:  vcu_if.comp_type = VSLE;
      OP_VMSLE:  vcu_if.comp_type = VSGTU;
      OP_VMSLE:  vcu_if.comp_type = VSGT;
      default:   vcu_if.comp_type = VSEQ;
    endcase
  end

  always_comb begin
    case(op_decoded)
      OP_VMIN, OP_VREDMIN:    vcu_if.minmax_type = MIN;
      OP_VMINU, OP_VREDMINU:  vcu_if.minmax_type = MINU;
      OP_VMAX, OP_VREDMAXU:   vcu_if.minmax_type = MAX;
      OP_VMAXU, OP_VREDMAX:   vcu_if.minmax_type = MAXU;
    default:                  vcu_if.minmax_type = MIN;
    endcase
  end

  always_comb begin
    case (op_decoded)
      OP_VZEXT_VF8: vcu_if.ext_type = F2Z;
      OP_VSEXT_VF8: vcu_if.ext_type = F2S;
      OP_VZEXT_VF4: vcu_if.ext_type = F4Z;
      OP_VSEXT_VF4: vcu_if.ext_type = F4S;
      OP_VZEXT_VF2: vcu_if.ext_type = F8Z;
      OP_VSEXT_VF2: vcu_if.ext_type = F8S;
    default:        vcu_if.ext_type = F2Z;
    endcase
  end

endmodule

