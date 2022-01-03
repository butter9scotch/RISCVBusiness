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
*   Filename:     tb/tb_vector_control_unit.sv
*
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/13/2021
*   Description:  testbench for vector control unit
*/
// `include "rvv_decoder.sv"
`include "rv32v_fetch2_decode_if.vh"
`include "rv32v_decode_execute_if.vh"
`include "rv32v_reg_file_if.vh"
`include "rv32v_hazard_unit_if.vh"
`include "prv_pipeline_if.vh"
`include "rv32v_top_level_if.vh"
`include "instruction.svh"
// `include "rvv_decoder.svh"
// `include "config_test.svh"

import rv32i_types_pkg::*;
// import rv32i_types_pkg::*;

//have all instructions inherit from one instruction parent class
//have an array of instructions, these contain the values of xs1, xs2


module tb_rv32v_top_level ();

  parameter PERIOD = 20;
  parameter MASKED = 0;
  parameter UNMASKED = 1;
  parameter VL = 16;

  logic CLK, nRST;
  vopm_t op;

  typedef int instr_list_t[];

  typedef struct packed {
    vopi_t funct6;
    logic vm;
    logic [4:0] rs2;
    logic [4:0] rs1;
    vfunct3_t funct3;
    logic [4:0] rd;
    opcode_t op;
  } vopi_ins;

  typedef struct packed {
    vopm_t funct6;
    logic vm;
    logic [4:0] rs2;
    logic [4:0] rs1;
    vfunct3_t funct3;
    logic [4:0] rd;
    opcode_t op;
  } vopm_ins;

  logic [31:0] xs1, xs2;
  logic scalar_hazard_if_ret;
  logic returnex;
  logic rd_wen;
  logic [4:0] rd_sel;
  logic [31:0] rd_data;

  int instr_idx;



  // Outputs to the DUT
  //logic [31:0] xs1, xs2;
  assign top_if.xs1 = xs1;
  assign top_if.xs2 = xs2;
  //logic scalar_hazard_if_ret;
  assign top_if.scalar_hazard_if_ret = scalar_hazard_if_ret;
  //logic returnex;
  assign top_if.returnex = returnex;



  rv32v_fetch2_decode_if  fetch_decode_if();
  cache_model_if cif();
  rv32v_hazard_unit_if hu_if();
  prv_pipeline_if prv_if();
  core_interrupt_if interrupt_if();
  rv32v_top_level_if top_if();


  rv32v_top_level      DUT (.*);
  priv_wrapper PRIV (.prv_pipe_if(prv_if), .*);



  initial begin : CLK_INIT
    CLK = 1'b0;
    nRST = 1;
  end : CLK_INIT

  always begin : CLK_GEN
    #(PERIOD/2) CLK = ~CLK;
  end : CLK_GEN
 
  task reset;
    @(negedge CLK);
    fetch_decode_if.tb_line_num = 0;
    fetch_decode_if.instr = 0;
    nRST = 0;
    @(posedge CLK);
    nRST = 1;
  endtask

  function vop_decoded_t decode(bit [31:0] instr);

    vfunct3_t vfunct3;
    vop_decoded_t op_decoded;
    bit is_vopi, is_vopm;
    vopi_t funct6_opi;
    vopm_t funct6_opm;
    rtype_t instr_r;
    bit [4:0] vs2;  
    bit [4:0] vd;
    bit [4:0] vs1;
    lumop_t lumop;
    width_t mem_op_width;
    mop_t mop;
    opcode_t opcode;

    bit[2:0] nf;
    bit vm;

    bit [4:0] imm_5;
    bit [10:0] zimm_11;
    bit [9:0] zimm_10;



    opcode       = opcode_t'(instr[6:0]);
    vfunct3      = vfunct3_t'(instr[14:12]);
    funct6_opi   = vopi_t'(instr[31:26]);
    funct6_opm   = vopm_t'(instr[31:26]);  
    is_vopi      = (opcode == VECTOR)  && (( vfunct3 == OPIVV) || (vfunct3 == OPIVX) || (vfunct3 == OPIVI));
    is_vopm      = (opcode == VECTOR)  && ( (vfunct3 == OPMVV) || (vfunct3 == OPMVX));
    vs2          = instr[24:20];
    vd           = instr[11:7]; 
    vs1          = instr[19:15];

    lumop        = lumop_t'(instr[24:20]);
    mem_op_width = width_t'(instr_r.funct3);
    mop          = mop_t'(instr[27:26]);
    nf           = instr[31:29];
    vm           = instr[25];
    imm_5        = instr[19:15];
    zimm_11      = instr[30:20];
    zimm_10      = instr[29:20];



    // always_comb begin
      if (is_vopi) begin
        case (funct6_opi)
          VADD:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VADD : BAD_OP  ;
          VSUB:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSUB : BAD_OP;
          VRSUB:  	  op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VRSUB : BAD_OP;
          VMINU:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMINU : BAD_OP;
          VMIN:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMIN : BAD_OP;
          VMAXU:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMAXU : BAD_OP;
          VMAX:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMAX : BAD_OP;
          VAND:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VAND : BAD_OP;
          VOR:        op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VOR : BAD_OP;
          VXOR:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VXOR : BAD_OP;
          VRGATHER:   op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VRGATHER : BAD_OP;
          VSLIDEUP:   op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSLIDEUP : (vfunct3 == OPIVV) ? OP_VRGATHEREI16 : BAD_OP;
          VSLIDEDOWN: op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSLIDEDOWN : BAD_OP;
          VADC:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VADC : BAD_OP;
          VMADC:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMADC : BAD_OP;
          VSBC:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSBC : BAD_OP;
          VMSBC:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMSBC : BAD_OP;
          VMERGE:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) && vm == BAD_OP ? OP_VMERGE : (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) && (vm == 0 )? OP_VMV : BAD_OP;
          VMSEQ:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSEQ : BAD_OP;
          VMSNE:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSNE : BAD_OP;
          VMSLTU:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMSLTU : BAD_OP;
          VMSLT:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VMSLT : BAD_OP;
          VMSLEU:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSLEU : BAD_OP;
          VMSLE:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSLE : BAD_OP;
          VMSGTU: 	  op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSGTU : BAD_OP;
          VMSGT: 	    op_decoded = (vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VMSGT : BAD_OP;
          VSADDU:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSADDU : BAD_OP;
          VSADD:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSADD : BAD_OP;
          VSSUBU:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSSUBU : BAD_OP;
          VSSUB:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ? OP_VSSUB : BAD_OP;
          VSLL:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSLL : BAD_OP;
          VSMUL:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) & ~vm ?  OP_VSMUL : 
                                    (vfunct3 == OPIVI) & (vm & (imm_5[2:0] == 3'd0)) ? OP_VMV1R : 
                                    (vfunct3 == OPIVI) &  vm & (imm_5[2:0] == 3'd1) ? OP_VMV2R : 
                                      (vfunct3 == OPIVI) &   vm & (imm_5[2:0] == 3'd3) ? OP_VMV4R : 
                                      (vfunct3 == OPIVI) &   vm & (imm_5[2:0] == 3'd7) ? OP_VMV8R : BAD_OP;
          VSRL:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSRL : BAD_OP;
          VSRA:       op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSRA : BAD_OP;
          VSSRL:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSSRL : BAD_OP;
          VSSRA:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VSSRA : BAD_OP;
          VNSRL:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VNSRL : BAD_OP;
          VNSRA:      op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VNSRA : BAD_OP;
          VNCLIPU:    op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VNCLIPU : BAD_OP;
          VNCLIP:     op_decoded = (vfunct3 == OPIVV) ||	(vfunct3 == OPIVX) ||	(vfunct3 == OPIVI) ? OP_VNCLIP : BAD_OP;
          VWREDSUMU:  op_decoded = (vfunct3 == OPIVV) ? 	OP_VWREDSUMU : BAD_OP;
          VWREDSUM:   op_decoded = (vfunct3 == OPIVV) ? OP_VWREDSUM : BAD_OP;
        endcase

      end else if (is_vopm) begin
        case (funct6_opm)
          VREDSUM:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDSUM   : BAD_OP;
          VREDAND:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDAND   : BAD_OP;
          VREDOR:       op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDOR    : BAD_OP;
          VREDXOR:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDXOR   : BAD_OP;
          VREDMINU:     op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDMINU    : BAD_OP;
          VREDMIN:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDMIN   : BAD_OP;
          VREDMAXU:     op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDMAXU    : BAD_OP;
          VREDMAX:      op_decoded = (vfunct3 == OPMVV)	 ? OP_VREDMAX   : BAD_OP;
          VAADDU:       op_decoded = (vfunct3 == OPMVV) ||	(vfunct3 == OPMVX) ? OP_VAADDU   : BAD_OP;
          VAADD:        op_decoded = (vfunct3 == OPMVV) ||	(vfunct3 == OPMVX) ? OP_VAADD    : BAD_OP;
          VASUBU:       op_decoded = (vfunct3 == OPMVV) ||	(vfunct3 == OPMVX) ? OP_VASUBU   : BAD_OP;
          VASUB:        op_decoded = (vfunct3 == OPMVV) ||	(vfunct3 == OPMVX) ? OP_VASUB    : BAD_OP;
          VSLIDE1UP:    op_decoded = (vfunct3 == OPMVX) ? OP_VSLIDE1UP   : BAD_OP;
          VSLIDE1DOWN:  op_decoded = (vfunct3 == OPMVX) ? OP_VSLIDE1DOWN   : BAD_OP;
          VWXUNARY0:    begin op_decoded =  (vfunct3 == OPMVV) && (vs1 == VMV_X_S) ? OP_VMV_X_S : 
                                            (vfunct3 == OPMVV) && (vs1 == VPOPC)   ? OP_VPOPC : 
                                            (vfunct3 == OPMVV) && (vs1 == VFIRST)  ? OP_VFIRST :
                                            (vfunct3 == OPMVX) && (vs2 == VMV_S_X) ? OP_VMV_S_X : BAD_OP;
                        end 
          VXUNARY0:     begin op_decoded =  (vfunct3 == OPMVV) && (vs1 == VZEXT_VF4) ?  OP_VZEXT_VF4 : 
                                            (vfunct3 == OPMVV) && (vs1 == VSEXT_VF4) ?  OP_VSEXT_VF4 : 
                                            (vfunct3 == OPMVV) && (vs1 == VZEXT_VF2) ?  OP_VZEXT_VF2 : 
                                            (vfunct3 == OPMVV) && (vs1 == VSEXT_VF2) ?  OP_VSEXT_VF2 : BAD_OP;
                                            // (vfunct3 == OPMVV) && (vs1 == VZEXT_VF8) ?  OP_VZEXT_VF8 : 
                                            // (vfunct3 == OPMVV) && (vs1 == VSEXT_VF8) ?  OP_VSEXT_VF8 : 
                        end 
          VMUNARY0:     begin op_decoded =  (vfunct3 == OPMVV) && (vs1 == VMSBF) ? OP_VMSBF : 
                                            (vfunct3 == OPMVV) && (vs1 == VMSOF) ? OP_VMSOF : 
                                            (vfunct3 == OPMVV) && (vs1 == VMSIF) ? OP_VMSIF : 
                                            (vfunct3 == OPMVV) && (vs1 == VIOTA) ? OP_VIOTA : 
                                            (vfunct3 == OPMVV) && (vs1 == VID)   ? OP_VID   : BAD_OP;
                        end 
          VCOMPRESS:    op_decoded = (vfunct3 == OPMVV)                       ? OP_VCOMPRESS : BAD_OP;
          VMANDN:     op_decoded = (vfunct3 == OPMVV)                       ? OP_VMANDN : BAD_OP;
          VMAND:        op_decoded = (vfunct3 == OPMVV)                       ? OP_VMAND : BAD_OP;
          VMOR:         op_decoded = (vfunct3 == OPMVV)                       ? OP_VMOR : BAD_OP;
          VMXOR:        op_decoded = (vfunct3 == OPMVV)                       ? OP_VMXOR : BAD_OP;
          VMORN:      op_decoded = (vfunct3 == OPMVV)                       ? OP_VMORN : BAD_OP;
          VMNAND:       op_decoded = (vfunct3 == OPMVV)                       ? OP_VMNAND : BAD_OP;
          VMNOR:        op_decoded = (vfunct3 == OPMVV)                       ? OP_VMNOR : BAD_OP;
          VMXNOR:       op_decoded = (vfunct3 == OPMVV)                       ? OP_VMXNOR : BAD_OP;
          VDIVU:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VDIVU : BAD_OP;
          VDIV:         op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VDIV : BAD_OP;
          VREMU:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VREMU : BAD_OP;
          VREM:         op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VREM : BAD_OP;
          VMULHU:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMULHU : BAD_OP;
          VMUL:         op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMUL : BAD_OP;
          VMULHSU:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMULHSU : BAD_OP;
          VMULH:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMULH : BAD_OP;
          VMADD:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMADD : BAD_OP;
          VNMSUB:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VNMSUB : BAD_OP;
          VMACC:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VMACC : BAD_OP;
          VNMSAC:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VNMSAC : BAD_OP;
          VWADDU:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWADDU : BAD_OP;
          VWADD:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWADD : BAD_OP;
          VWSUBU:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWSUBU : BAD_OP;
          VWSUB:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWSUB : BAD_OP;
          VWADDU_W:     op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWADDU_W : BAD_OP;
          VWADD_W:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWADD_W : BAD_OP;
          VWSUBU_W:     op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWSUBU_W : BAD_OP;
          VWSUB_W:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWSUB_W : BAD_OP;
          VWMULU:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMULU : BAD_OP;
          VWMULSU:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMULSU : BAD_OP;
          VWMUL:        op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMUL : BAD_OP;
          VWMACCU:      op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMACCU : BAD_OP;
          VWMACC:       op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMACC : BAD_OP;
          VWMACCUS:     op_decoded = (vfunct3 == OPMVX)                       ? OP_VWMACCUS : BAD_OP;
          VWMACCSU:     op_decoded = (vfunct3 == OPMVV)||	(vfunct3 == OPMVX)  ? OP_VWMACCSU : BAD_OP;
        endcase
      end
    // end

    return op_decoded;

  endfunction

  function bit [31:0] check_32(
    vop_decoded_t op,
    int vs1, vs2, vd
  );

    case (op)
    OP_VADD: begin
      // $info ("%h-%h-%h", vs1, vs2, vd);
        return (vs1 + vs2) ;
    end
    OP_VSUB: begin
        return (vs2 - vs1);
    end
    OP_VRSUB: begin
        return (vs1 - vs2);
    end

    //Multiply-add 
    OP_VMACC: begin
        return vs1 * vs2 + vd;
    end
    OP_VNMSAC: begin
        return (vs1 * vs2) * -1 + vd;
    end
    OP_VMACC: begin
        return (vs1 * vd) + vs2;
    end
    OP_VNMSUB: begin
        return (vs1 * vd) * -1 + vs2;
    end
    endcase

  endfunction

  function bit checker(
    vop_decoded_t op,
    logic [127:0] data0, //vm
    logic [127:0] data1, //vs1
    logic [127:0] data2, //vs2
    logic [127:0] data3, //vs3
    logic [127:0] actual
  );
    logic [31:0] expected;
    
    int i;
    bit [3:0] result;
    int u, l;

    for (i = 0; i < 4; i += 1) begin
      u = i * 32 + 31;
      l = i * 32;
      
      expected = check_32(op, data1[l+:32], data2[l+:32], data3[l+:32]);
      result[i] = check_32(op, data1[l+:32], data2[l+:32], data3[l+:32]) == actual[l+:32];
      if (!result[i]) begin
        $display("Incorrect result. Expected: %h --- actual %h", expected, actual[l+:32]);
      end
    end


    if (result == 4'hF) begin
      $display("%s -- SUCCESS", op.name());
    end else begin
      $display("%s -- FAIL", op.name());
    end
    



  endfunction





  task load_reg_data;
    input logic [4:0] sel;
    input logic [127:0] data;
  // `ifdef TESTBENCH
    @(negedge CLK);
    DUT.reg_file.tb_ctrl = 1;
    DUT.reg_file.tb_sel = sel;
    DUT.reg_file.tb_data = data;
    @(posedge CLK);
    #(1);
    DUT.reg_file.tb_ctrl = 0;
  endtask

  task init();
    reset();
    // xs1 = VL;
    xs2 = {24'd0, 2'd0, SEW32, LMUL2}; //if vsetvl
    scalar_hazard_if_ret = 0;
    returnex = 0;
    fetch_decode_if.fault_insn = 0;
    fetch_decode_if.mal_insn = 0;
    cif.dhit = 0;
    cif.dmemload = 0;

  endtask

  task display_reg;
    input logic [4:0] rs;

    automatic int i;
    automatic int sum;
    sum = 0;
    for (i = VLENB - 1; i >= 0; i--) begin
      sum |= DUT.reg_file.registers[rs][i];
    end
    if (sum != 0) begin
      $write("register[%d]: ", rs);
      for (i = VLENB - 1; i >= 0; i--) begin
        if (i % 4 == 3 && (i != 15)) begin
          $write(" --- [%x]", DUT.reg_file.registers[rs][i]);
        end else begin
          $write(" [%x]", DUT.reg_file.registers[rs][i]);
        end
      end
      $write("\n");
    end
    // $display("[%x] [%x] [%x] [%x] [%x] [%x] [%x] [%x]", DUT.registers[vs1][7], DUT.registers[vs1][6],DUT.registers[vs1][5],DUT.registers[vs1][4],DUT.registers[vs1][3],DUT.registers[vs1][2],DUT.registers[vs1][1],DUT.registers[vs1][0]);
    // #2;
  endtask

  task display_reg_file;
    automatic int i;
    $write("\n");
    for (i = 0; i < 32; i++) begin
      display_reg(i);
    end
    $write("\n");

  endtask
    
  // Run new testcase
  task add_test_case;

    input int line_buffer [];
    input logic [127:0] data0;
    input logic [127:0] data1;
    input logic [127:0] data2;
    input logic [127:0] data3;
    logic [127:0] actual;

    instr_list_t instr_mem;
    vopi_ins ins_i;
    vopm_ins ins_m;
    vop_cfg ins_c;
    vop_decoded_t op;

    instr_idx = 0;
    instr_mem = line_buffer;
    init();
    load_reg_data(0, data0);
    load_reg_data(1, data1); 
    load_reg_data(2, data2); 
    load_reg_data(3, data3); 

    @(posedge CLK);
    #(PERIOD * 3);
    //Do one test case
    for (instr_idx = 0; instr_idx < line_buffer.size(); instr_idx++) begin 
      ins_i  = vopi_ins'(line_buffer[instr_idx]);
      ins_m  = vopm_ins'(line_buffer[instr_idx]);
      ins_c = vop_cfg'(line_buffer[instr_idx]);
      fetch_decode_if.instr = line_buffer[instr_idx];
      fetch_decode_if.tb_line_num = instr_idx;
      do begin
        if (hu_if.csr_update) begin instr_idx = DUT.memory_writeback_if.tb_line_num; end
        // $info("inside wait, csr_update: %d, tb_line_num: %d", );
        @(posedge CLK); 
        #(1);
      end while(hu_if.busy_dec);      
      @(posedge CLK);
    end

    
    op = decode(line_buffer[1]);
    actual = DUT.reg_file.registers[3][15:0];
    display_reg_file();
    checker(op, data0, data1, data2, data3, actual);
      
    #(PERIOD * 3);

  endtask




  function instr_list_t new_config_vop_case(
     sew_t sew,
     vlmul_t lmul,
     int vl,
     vopi_t funct6,
     vfunct3_t funct3,
     bit vm
  );
    // output int [] out;

    Vsetvli v;
    RegReg r;
    RegReg a;

    logic [4:0] vs1, vs2, vd;

    if (lmul == LMUL1) begin vs1 = 1; vs2 = 2; vd = 3; end
    else if (lmul == LMUL2) begin vs1 = 1; vs2 = 3; vd = 5;  end 
    else if (lmul == LMUL4) begin vs1 = 1; vs2 = 5; vd = 9;  end 
    else if (lmul == LMUL8) begin vs1 = 1; vs2 = 9; vd = 17; end 

    xs1 = vl;

    v = new(sew, lmul, 1, 2);
    r = new(funct6, vm, vs2, vs1, funct3, vd);
    a = new(VADD, 1, 31, 0, OPIVI, 31);

    return {v.instr, r.instr, a.instr};
    // return {v.instr, r.instr};
  
  endfunction

  
  function instr_list_t new_config_vop_reg_case(
     sew_t sew,
     vlmul_t lmul,
     int vl,
     vopm_t funct6,
     vfunct3_t funct3,
     bit vm, 
     logic [4:0] vs1
  );
    // output int [] out;

    Vsetvli v;
    RegReg r;
    RegReg a;


    logic [4:0]  vs2, vd;

    if (lmul == LMUL1) begin  vs2 = 2; vd = 3; end
    else if (lmul == LMUL2) begin vs2 = 3; vd = 5;  end 
    else if (lmul == LMUL4) begin vs2 = 5; vd = 9;  end 
    else if (lmul == LMUL8) begin vs2 = 9; vd = 17; end 

    xs1 = vl;

    v = new(sew, lmul, 1, 2);
    r = new(funct6, vm, vs2, vs1, funct3, vd);
    a = new(VADD, 1, 31, 0, OPIVI, 31);


    // return {v.instr, r.instr};
    return {v.instr, r.instr, a.instr};

  
  endfunction

  task check_outputs;
    input logic [255:0] expected;
    // $info("%d, %d, %d, %d", DUT.reg_file.registers[6][15:12], DUT.reg_file.registers[6][11:8], DUT.reg_file.registers[6][7:4], DUT.reg_file.registers[6][3:0]);
    // $display("%d, %d, %d, %d", DUT.reg_file.registers[1][15:12], DUT.reg_file.registers[1][11:8], DUT.reg_file.registers[1][7:4], DUT.reg_file.registers[1][3:0]);
    if (expected == {DUT.reg_file.registers[6], DUT.reg_file.registers[5]}) $display("correct");
      // $display("");
  endtask

  bit [31:0] line;
  // vopi_ins ins_i;
  // vopm_ins ins_m;
  // vop_cfg ins_c;
  int i, old_i;
  RegReg rri;



  initial begin : MAIN
    fetch_decode_if.instr = 0;
    // read_init_file("rv32v/tb/init.hex", instr_mem);
    // add_test_case({32'h0910F2D7, 32'h0011C2D7});
    // rri = new(VADD, 1'b0, 1, 3, OPIVV, 5);
    // $display("%x", rri.instr);
    // add_test_case(new_config_vop_case(SEW32, LMUL2, 8, VMULHU, OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW32, LMUL2, 8, VREDSUM, OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW32, LMUL2, 8, VMUL, OPMVV, UNMASKED)); //VMV
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 8, VMUL,    OPMVV, UNMASKED)); //VMV
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 8, VWMULU,  OPMVV, UNMASKED)); //VMV
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 8, VWMULSU, OPMVV, UNMASKED)); //VMV
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 8, VWMUL,   OPMVV, UNMASKED)); //VMV
    
    // vd[i] = +(vs1[i] * vs2[i]) + vd[i]
    add_test_case(new_config_vop_case(SEW32, LMUL1, 4, VADD, OPIVV, UNMASKED),
      {{30{4'hF}}, 8'h55},
      {32'h7, 32'h6, 32'h5, 32'h2},
      {32'h3, 32'h2, 32'h1, 32'h3},
      {32'hf, 32'hd, 32'hb, 32'h5}
    ); 
    add_test_case(new_config_vop_case(SEW32, LMUL1, 4, VMADD, OPMVV, UNMASKED),
      {{30{4'hF}}, 8'h55},
      {32'h7, 32'h6, 32'h5, 32'h2},
      {32'h3, 32'h2, 32'h1, 32'h3},
      {32'hf, 32'hd, 32'hb, 32'h5}
    ); 

    // vd[i] = -(vs1[i] * vs2[i]) + vd[i]
    add_test_case(new_config_vop_case(SEW32, LMUL1, 4, VNMSUB, OPMVV, UNMASKED), //VMV
      {{30{4'hF}}, 8'h55},
      {32'h7, 32'h6, 32'h5, 32'h2},
      {32'h3, 32'h2, 32'h1, 32'h3},
      {32'hf, 32'hd, 32'hb, 32'h5}
    );
    // vd[i] = (vs1[i] * vd[i]) + vs2[i]
    add_test_case(new_config_vop_case(SEW32, LMUL1, 4, VMACC, OPMVV, UNMASKED), //VMV
      {{30{4'hF}}, 8'h55},
      {32'h7, 32'h6, 32'h5, 32'h2},
      {32'h3, 32'h2, 32'h1, 32'h3},
      {32'hf, 32'hd, 32'hb, 32'h5}
    );
    // vd[i] = -(vs1[i] * vd[i]) + vs2[i]
    add_test_case(new_config_vop_case(SEW32, LMUL1, 4, VNMSAC, OPMVV, UNMASKED), //VMV
      {{30{4'hF}}, 8'h55},
      {32'h7, 32'h6, 32'h5, 32'h2},
      {32'h3, 32'h2, 32'h1, 32'h3},
      {32'hf, 32'hd, 32'hb, 32'h5}
    );

    // add_test_case(new_config_vop_case(SEW16, LMUL2, 8, VWMULU,  OPMVV, UNMASKED)); //VMV
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 8, VWMULSU, OPMVV, UNMASKED)); //VMV
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 8, VWMUL,   OPMVV, UNMASKED)); //VMV
    // add_test_case(new_config_vop_reg_case(SEW16, LMUL2, 16, VSMUL, OPIVI, UNMASKED, 0));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16, VADD, OPIVV, MASKED));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16, VADD, OPIVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW32, LMUL2, 8,  VMUL, OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW32, LMUL2, 8,  VRSUB, OPIVI, UNMASKED));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16,  VMUNARY0, OPMVV, UNMASKED));
    // add_test_case(new_config_vop_reg_case(SEW16, LMUL2, 16, VMUNARY0, OPMVV, UNMASKED, VMSBF));
    // add_test_case(new_config_vop_reg_case(SEW16, LMUL2, 16, VMUNARY0, OPMVV, UNMASKED, VMSIF));
    // add_test_case(new_config_vop_reg_case(SEW16, LMUL2, 16, VMUNARY0, OPMVV, UNMASKED, VMSOF));
    //add_test_case(new_config_vop_reg_case(SEW16, LMUL2, 16, VMUNARY0, OPMVV, UNMASKED, VMSBF));
    // add_test_case(new_config_vop_reg_case(SEW32, LMUL2, 8,  VXUNARY0, OPMVV, UNMASKED, VZEXT_VF4));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16, VWSUBU_W, OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16, VWSUB_W,  OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW16, LMUL2, 16, VWADD_W,  OPMVV, UNMASKED));
    // add_test_case(new_config_vop_case(SEW32, LMUL2, VDIV, OPMVV, UNMASKED));


    // op = VWMACCSU;
    // if (op inside {VWMACCSU, VWMACCUS}) $write("\n\n\n\nSUCCESS\n\n\n\n");

    $finish;
  end : MAIN
endmodule

