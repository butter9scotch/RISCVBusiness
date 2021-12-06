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
*   Filename:     include/rv32v_reg_file_if.vh
*
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/30/2021
*   Description:  Decode-execute interface for vector extension 
*/

`include "rv32v_fetch2_decode_if.vh"
`include "rv32v_decode_execute_if.vh"
`include "rv32v_reg_file_if.vh"
`include "rv32v_hazard_unit_if.vh"
`include "prv_pipeline_if.vh"
`include "microop_buffer_if.vh"

module rv32v_decode_stage (
  input logic CLK, nRST, halt,
  rv32v_fetch2_decode_if.decode fetch_decode_if,
  rv32v_decode_execute_if.decode decode_execute_if,
  rv32v_reg_file_if.decode rfv_if,
  rv32v_hazard_unit_if.decode hu_if,
  prv_pipeline_if.vdecode prv_if,
  input logic [31:0] xs1, xs2,
  input logic scalar_hazard_if_ret
);

  import rv32i_types_pkg::*;
  import rv32v_types_pkg::*;

  parameter TODO = 0;
  
  vector_control_unit_if vcu_if();
  element_counter_if ele_if();
  // microop_buffer_if uop_if();

  vector_control_unit vcu(.*);
  element_counter  element_counter(.*);
  // microop_buffer uop_buffer(.*);

  sew_t sew;
  vlmul_t lmul;
  logic [31:0] vstart;
  vop_cfg vop_c;
  logic wen0, wen1;

  assign vop_c = vop_cfg'(fetch_decode_if.instr);

  assign sew = vcu_if.mask_ena ? SEW32 : sew_t'(prv_if.vtype[5:3]);
  assign lmul = vlmul_t'(prv_if.vtype[2:0]);

  // vector control unit assigns
  assign vcu_if.instr = fetch_decode_if.instr;
  // element counter assigns
  assign ele_if.vstart    = prv_if.vstart; 
  assign ele_if.vl        = vcu_if.mask_logical ? 4 : prv_if.vl;  
  // assign ele_if.stall     = hu_if.stall_dec | vcu_if.stall;  
  assign ele_if.stall     = hu_if.busy_ex | vcu_if.stall;  
  // assign ele_if.stall     = hu_if.stall_dec | vcu_if.stall;  
  assign ele_if.ex_return = scalar_hazard_if_ret;  //TODO: check this
  assign ele_if.de_en     = vcu_if.de_en;   
  assign ele_if.sew       = sew; 
  assign ele_if.clear     = hu_if.flush_dec;
  assign ele_if.busy_ex   = hu_if.busy_ex;
  assign ele_if.slide1up  = vcu_if.vd_offset_src == VD_SRC_IDX_PLUS_1;
  // assign ele_if.clear     = ~vcu_if.de_en | hu_if.flush_dec; //TODO: check this 

  logic [31:0] sign_ext_imm5, zero_ext_imm5;
  assign sign_ext_imm5 = {{27{vcu_if.imm_5[4]}}, vcu_if.imm_5};
  assign zero_ext_imm5 = {27'd0, vcu_if.imm_5};

  // assign vstart = 0; //TODO
  // assign hu_if.busy_dec = vcu_if.de_en | (ele_if.offset != 0 && ~ele_if.done);
  // assign hu_if.busy_dec = ~vcu_if.illegal_insn & (~ele_if.done);

  // microop buffer assigns


  offset_t woffset0, woffset1, vs1_offset0, vs1_offset1, vs2_offset0, vs2_offset1;

  logic mask0, mask1;

  sew_t next_decode_execute_if_eew;

  always_ff @(posedge CLK, negedge nRST) begin
    if(~nRST)begin
      hu_if.busy_dec <= 0;
    end else begin
      if (hu_if.busy_dec == 0 && vcu_if.de_en ) begin
        hu_if.busy_dec <= 1;
      end
      else if (hu_if.busy_dec == 1 && ele_if.done) begin
        hu_if.busy_dec <= 0;
      end
    end
  end

  always_comb begin
    next_decode_execute_if_eew = sew;
    if (vcu_if.vd_widen) begin
      case(sew)
        SEW32, SEW16: next_decode_execute_if_eew = SEW32;
        SEW8: next_decode_execute_if_eew = SEW16;
      endcase
    end else if (vcu_if.vd_narrow) begin
      case(sew)
        SEW32 : next_decode_execute_if_eew = SEW16;
        SEW16, SEW8: next_decode_execute_if_eew = SEW8;
      endcase
    end 
  end

  always_comb begin
    rfv_if.vs2_sew = sew;
    if (vcu_if.win) begin
      case(sew)
        SEW32, SEW16: rfv_if.vs2_sew = SEW32;
        SEW8: rfv_if.vs2_sew = SEW16;
      endcase
    end else if (vcu_if.aluop == VALU_EXT) begin
      case (vcu_if.ext_type)
        F4Z, F4S: rfv_if.vs2_sew = (sew == SEW32) ? SEW8 : sew;
        F2Z, F2S: rfv_if.vs2_sew = (sew == SEW32) ? SEW16 : (sew == SEW16) ? SEW8 : sew;
      endcase
    end
  end

  //TODO: iron out exact masking logic based on offsets
  always_comb begin : MASK_BITS
    if (vcu_if.vs1_offset_src == NORMAL) begin
      mask0 = ~vcu_if.vm ? rfv_if.vs1_mask[0] : 1;
      mask1 = ~vcu_if.vm ? rfv_if.vs1_mask[1] : 1;
    end else if (vcu_if.vs2_offset_src == NORMAL) begin
      mask0 = ~vcu_if.vm ? rfv_if.vs2_mask[0] : 1;
      mask1 = ~vcu_if.vm ? rfv_if.vs2_mask[1] : 1;
    end else begin
      mask0 = ~vcu_if.vm ? rfv_if.vs3_mask[0] : 1;
      mask1 = ~vcu_if.vm ? rfv_if.vs3_mask[1] : 1;
    end
  end

  always_comb begin
    if (vcu_if.reduction_ena) begin
      wen0 = ele_if.next_done;
      wen1 = 0;
    end else begin
      wen0 = (vcu_if.result_type == A_S) ? 1 : vcu_if.wen & (mask0);
      wen1 = (vcu_if.result_type == A_S) ? 1: vcu_if.wen & (mask1);
    end
  end

  always_comb begin : VS1_OFFSET
    case(vcu_if.vs1_offset_src)
    VS1_SRC_NORMAL: begin 
            vs1_offset0 = ele_if.offset;
            vs1_offset1 = ele_if.offset + 1;
    end
    VS1_SRC_ZERO: begin 
            vs1_offset0 = 0;
            vs1_offset1 = 0;
    end
  endcase
  end

  always_comb begin : VS2_OFFSET
    case(vcu_if.vs2_offset_src)
      VS2_SRC_NORMAL: begin 
              vs2_offset0 = ele_if.offset;
              vs2_offset1 = ele_if.offset + 1;
      end
      VS2_SRC_IDX_PLUS_RS1: begin 
              vs2_offset0 = ele_if.offset + xs1;
              vs2_offset1 = ele_if.offset + xs1 + 1;
      end
      VS2_SRC_IDX_PLUS_UIMM: begin 
            vs2_offset0 = ele_if.offset + zero_ext_imm5;
            vs2_offset1 = ele_if.offset + zero_ext_imm5 + 1;
      end
      VS2_SRC_IDX_PLUS_1: begin 
            vs2_offset0 = ele_if.offset + 1;
            vs2_offset1 = ele_if.offset + 2; 
      end
      VS2_SRC_IDX_MINUS_1: begin 
            vs2_offset0 = ele_if.offset - 1;
            vs2_offset1 = ele_if.offset; 
      end
      VS2_SRC_VS1: begin 
            vs2_offset0 = rfv_if.vs1_data[0];
            vs2_offset1 = rfv_if.vs1_data[1];
      end
      VS2_SRC_RS1: begin 
            vs2_offset0 = xs1;
            vs2_offset1 = xs1;
      end
      VS2_SRC_UIMM: begin 
            vs2_offset0 = zero_ext_imm5[VLEN_WIDTH:0];
            vs2_offset1 = zero_ext_imm5[VLEN_WIDTH:0];
      end
      VS2_SRC_ZERO: begin
            vs2_offset0 = 0;
            vs2_offset1 = 0;
      end
    endcase
  end

  always_comb begin : WOFFSET
    case (vcu_if.vd_offset_src)
      VD_SRC_NORMAL: begin   
        woffset0 = ele_if.offset;
        woffset1 = ele_if.offset + 1;
      end       
      VD_SRC_ZERO: begin   
        woffset0 = 0;
        woffset1 = 0;
      end         
      VD_SRC_IDX_PLUS_RS1:  begin  
        woffset0 = ele_if.offset + xs1;
        woffset1 = ele_if.offset + xs1 + 1;
      end
      VD_SRC_IDX_PLUS_UIMM: begin  
        woffset0 = ele_if.offset + zero_ext_imm5;
        woffset1 = ele_if.offset + zero_ext_imm5 + 1;
      end
      VD_SRC_IDX_PLUS_1:  begin  
        woffset0 = ele_if.offset + 1;
        woffset1 = ele_if.offset + 2;
      end         
      VD_SRC_COMPRESS: begin   
        woffset0 = ele_if.offset;      //this will need to change 
        woffset1 = ele_if.offset + 1; //this will need to change
      end       
    endcase
  end

    // in:  vs1, vs2, vs1_offset, vs2_offset, sew, 
    // out: vs1_data, vs2_data, vs3_data, vs1_mask, vs2_mask

  assign rfv_if.vs1 = vcu_if.vs1;
  assign rfv_if.vs2 = vcu_if.vs2;
  assign rfv_if.vs3 = vcu_if.vd;
  assign rfv_if.vs1_offset = vs1_offset0;
  // assign rfv_if.vs1_offset[1] = vs1_offset1;
  assign rfv_if.vs2_offset = vs2_offset0;
  // assign rfv_if.vs2_offset[1] = vs2_offset1;
  assign rfv_if.vs3_offset = woffset0; // use offset of vd here because same bits in instruction
  // assign rfv_if.vs3_offset[1] = woffset1; // use offset of vd here because same bits in instruction
  assign rfv_if.sew = sew;
  // assign rfv_if.vl = prv_if.vl;
  // assign rfv_if.vs2_sew = vcu_if.vs2_widen ? (prv_if.sew == SEW32) || (prv_if.sew == SEW16) ? SEW32 : 
                                              // (prv_if.sew == SEW8) ? SEW16 : prv_if.sew;

                                              
                                              
  always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
      decode_execute_if.stride_type       <= '0;
      decode_execute_if.rd_wen            <= '0;
      decode_execute_if.rd_data           <= '0;
      decode_execute_if.config_type       <= '0;
      decode_execute_if.mask0             <= '0;
      decode_execute_if.mask1             <= '0;
      decode_execute_if.reduction_ena     <= '0;
      decode_execute_if.is_signed         <= '0;
      decode_execute_if.ls_idx            <= '0;
      decode_execute_if.load              <= '0;
      decode_execute_if.store             <= '0;
      decode_execute_if.wen[0]            <= '0;
      decode_execute_if.wen[1]            <= '0;
      decode_execute_if.stride_val        <= '0;
      decode_execute_if.xs1               <= '0;
      decode_execute_if.xs2               <= '0;
      decode_execute_if.vs1_lane0         <= '0;
      decode_execute_if.vs1_lane1         <= '0;
      decode_execute_if.vs3_lane0         <= '0;
      decode_execute_if.vs3_lane1         <= '0;
      decode_execute_if.vs2_lane0         <= '0;
      decode_execute_if.vs2_lane1         <= '0;
      decode_execute_if.imm               <= '0;
      decode_execute_if.storedata0        <= '0;
      decode_execute_if.storedata1        <= '0;
      decode_execute_if.rd_sel            <= '0;
      decode_execute_if.woffset0          <= '0;
      decode_execute_if.woffset1          <= '0;
      decode_execute_if.fu_type           <= '0;
      decode_execute_if.result_type       <= '0;
      decode_execute_if.aluop             <= '0;
      decode_execute_if.rs1_type          <= '0;
      decode_execute_if.rs2_type          <= '0;
      decode_execute_if.minmax_type       <= '0;
      decode_execute_if.eew               <= '0;
      decode_execute_if.vl                <= '0;
      decode_execute_if.vlenb             <= '0;
      decode_execute_if.vtype             <= '0;
      
      decode_execute_if.div_type          <= '0;
      decode_execute_if.is_signed_div     <= '0;
      decode_execute_if.high_low          <= '0;
      decode_execute_if.is_signed_mul     <= '0;
      decode_execute_if.mul_widen_ena     <= '0;
      decode_execute_if.multiply_pos_neg  <= '0;
      decode_execute_if.multiply_type     <= '0;
      //new
      decode_execute_if.sew               <= '0;
      decode_execute_if.lmul              <= '0;
      //arith signals
      decode_execute_if.comp_type         <= '0;
      decode_execute_if.adc_sbc           <= '0;
      decode_execute_if.carry_borrow_ena  <= '0;
      decode_execute_if.carryin_ena       <= '0;
      decode_execute_if.rev               <= '0;
      decode_execute_if.ext_type          <= '0;

      decode_execute_if.woutu             <= '0;
      decode_execute_if.win               <= '0;
      decode_execute_if.zext_w            <= '0;

      decode_execute_if.vd                <= '0;
      decode_execute_if.single_bit_write  <= '0;

      decode_execute_if.vstart            <= '0;
      decode_execute_if.next_vtype_csr    <= '0;
      decode_execute_if.next_avl_csr      <= '0;
      decode_execute_if.vd_widen          <= '0;

      decode_execute_if.vs2_offset0       <= '0;
      decode_execute_if.vs2_offset1       <= '0;

      decode_execute_if.is_masked         <= '0;
      decode_execute_if.vd_narrow         <= '0;

      decode_execute_if.mask_type         <= '0;

      decode_execute_if.mask_32bit_lane0  <= '0;
      decode_execute_if.mask_32bit_lane1  <= '0;
      decode_execute_if.out_inv           <= '0;
      decode_execute_if.in_inv            <= '0;

      //TESTBENCH ONLY
      decode_execute_if.tb_line_num        <= 0;


    end else if(hu_if.flush_dec) begin
      decode_execute_if.stride_type       <= '0;
      decode_execute_if.rd_wen            <= '0;
      decode_execute_if.config_type       <= '0;
      decode_execute_if.mask0             <= '0;
      decode_execute_if.mask1             <= '0;
      decode_execute_if.reduction_ena     <= '0;
      decode_execute_if.is_signed         <= '0;
      decode_execute_if.ls_idx            <= '0;
      decode_execute_if.load              <= '0;
      decode_execute_if.store             <= '0;
      decode_execute_if.wen[0]            <= '0;
      decode_execute_if.wen[1]            <= '0;
      decode_execute_if.stride_val        <= '0;
      decode_execute_if.xs1               <= '0;
      decode_execute_if.xs2               <= '0;
      decode_execute_if.vs1_lane0         <= '0;
      decode_execute_if.vs1_lane1         <= '0;
      decode_execute_if.vs3_lane0         <= '0;
      decode_execute_if.vs3_lane1         <= '0;
      decode_execute_if.vs2_lane0         <= '0;
      decode_execute_if.vs2_lane1         <= '0;
      decode_execute_if.imm               <= '0;
      decode_execute_if.storedata0        <= '0;
      decode_execute_if.storedata1        <= '0;
      decode_execute_if.rd_sel            <= '0;
      decode_execute_if.woffset0          <= '0;
      decode_execute_if.woffset1          <= '0;
      decode_execute_if.fu_type           <= '0;
      decode_execute_if.result_type       <= '0;
      decode_execute_if.aluop             <= '0;
      decode_execute_if.rs1_type          <= '0;
      decode_execute_if.rs2_type          <= '0;
      decode_execute_if.minmax_type       <= '0;
      decode_execute_if.eew               <= '0; 
      decode_execute_if.vl                <= '0;      
      decode_execute_if.vlenb             <= '0;   
      decode_execute_if.vtype             <= '0;   

      decode_execute_if.div_type          <= '0;
      decode_execute_if.is_signed_div     <= '0;
      decode_execute_if.high_low          <= '0;
      decode_execute_if.is_signed_mul     <= '0;
      decode_execute_if.mul_widen_ena     <= '0;
      decode_execute_if.multiply_pos_neg  <= '0;
      decode_execute_if.multiply_type     <= '0;
      //new
      decode_execute_if.sew               <= '0;
      decode_execute_if.lmul              <= '0;
      //missing arith
      decode_execute_if.comp_type         <= '0;
      decode_execute_if.adc_sbc           <= '0;
      decode_execute_if.carry_borrow_ena  <= '0;
      decode_execute_if.carryin_ena       <= '0;
      decode_execute_if.rev               <= '0;
      decode_execute_if.ext_type          <= '0;

      decode_execute_if.woutu             <= '0;
      decode_execute_if.win               <= '0;
      decode_execute_if.zext_w            <= '0;

      decode_execute_if.vd                <= '0;
      decode_execute_if.single_bit_write  <= '0;
      decode_execute_if.vstart            <= '0;
      decode_execute_if.next_vtype_csr    <= '0;
      decode_execute_if.next_avl_csr      <= '0;
      decode_execute_if.rd_data           <= '0;
      decode_execute_if.vd_widen          <= '0;

      decode_execute_if.vs2_offset0       <= '0;
      decode_execute_if.vs2_offset1       <= '0;

      decode_execute_if.is_masked         <= '0;

      decode_execute_if.vd_narrow         <= '0;

      decode_execute_if.mask_type         <= '0;
      decode_execute_if.mask_32bit_lane0  <= '0;
      decode_execute_if.mask_32bit_lane1  <= '0;
      decode_execute_if.out_inv           <= '0;
      decode_execute_if.in_inv           <= '0;


      //TESTBENCH ONLY
      decode_execute_if.tb_line_num        <= 0;



    end else if (~hu_if.stall_dec) begin
      decode_execute_if.stride_type   <= vcu_if.stride_type;
      decode_execute_if.rd_wen        <= vcu_if.rd_scalar_src; //write to scalar regs
      decode_execute_if.config_type   <= vcu_if.cfgsel;
      decode_execute_if.mask0         <= mask0; //double check, will it always be vs1_mask
      decode_execute_if.mask1         <= mask1; //double check, will it always be vs1_mask
      decode_execute_if.reduction_ena <= vcu_if.reduction_ena; 
      decode_execute_if.is_signed     <= vcu_if.is_signed;
      decode_execute_if.ls_idx        <= (vcu_if.mop == MOP_OINDEXED) || (vcu_if.mop == MOP_UINDEXED);
      decode_execute_if.load          <= vcu_if.is_load;
      decode_execute_if.store         <= vcu_if.is_store;
      decode_execute_if.wen[0]        <= wen0;
      decode_execute_if.wen[1]        <= wen1;
      decode_execute_if.stride_val    <= xs2; //from xs2 field in instr; 
      decode_execute_if.xs1           <= xs1; 
      decode_execute_if.xs2           <= xs2; 
      decode_execute_if.vs1_lane0     <= rfv_if.vs1_data[0];
      decode_execute_if.vs1_lane1     <= rfv_if.vs1_data[1]; //vs1_data1 is not good?
      decode_execute_if.vs2_lane0     <= vcu_if.vd_narrow & (sew == SEW32) ? {16'd0, rfv_if.vs2_data[0][15:0]} : 
                                          vcu_if.vd_narrow & (sew == SEW16) ? {24'd0, rfv_if.vs2_data[0][7:0]} : 
                                          vcu_if.vs2_offset_src == VS2_SRC_IDX_MINUS_1 & (vs2_offset1 == prv_if.vstart) ? xs1 : 
                                          vcu_if.vs2_offset_src == VS2_SRC_IDX_PLUS_1 & (vs2_offset0 == prv_if.vl) ? xs1 : 
                                          rfv_if.vs2_data[0];
      decode_execute_if.vs2_lane1     <= vcu_if.vd_narrow & (sew == SEW32) ? {16'd0, rfv_if.vs2_data[1][15:0]} : 
                                          vcu_if.vd_narrow & (sew == SEW16) ? {24'd0, rfv_if.vs2_data[1][7:0]} : 
                                          vcu_if.vs2_offset_src == VS2_SRC_IDX_PLUS_1 & (vs2_offset1 == prv_if.vl) ? xs1 : 
                                          rfv_if.vs2_data[1];
      decode_execute_if.vs3_lane0     <= rfv_if.vs3_data[0];
      decode_execute_if.vs3_lane1     <= rfv_if.vs3_data[1];
      decode_execute_if.imm           <= vcu_if.is_signed ? sign_ext_imm5 : zero_ext_imm5; // sign extend, i think this works
      decode_execute_if.storedata0    <= rfv_if.vs3_data[0];
      decode_execute_if.storedata1    <= rfv_if.vs3_data[1];
      decode_execute_if.rd_sel        <= vcu_if.vd;
      decode_execute_if.woffset0      <=  woffset0; //TODO: add decision logic here
      decode_execute_if.woffset1      <=  woffset1; //TODO: add decision logic here
      decode_execute_if.fu_type       <= vcu_if.fu_type;
      decode_execute_if.result_type   <= vcu_if.result_type;
      decode_execute_if.aluop         <= vcu_if.aluop;
      decode_execute_if.rs1_type      <= vcu_if.rs1_type;
      decode_execute_if.rs2_type      <= vcu_if.rs2_type;
      decode_execute_if.minmax_type   <= vcu_if.minmax_type;
      decode_execute_if.eew           <= next_decode_execute_if_eew; //TODO: after adding widening, change this     
      decode_execute_if.vl            <= prv_if.vl;      
      decode_execute_if.vlenb         <= prv_if.vlenb;   
      decode_execute_if.vtype         <= prv_if.vtype;   
      decode_execute_if.div_type          <= vcu_if.div_type;
      decode_execute_if.is_signed_div     <= vcu_if.is_signed_div;
      decode_execute_if.high_low          <= vcu_if.high_low;
      decode_execute_if.is_signed_mul     <= vcu_if.is_signed_mul;
      decode_execute_if.mul_widen_ena     <= vcu_if.mul_widen_ena;
      decode_execute_if.multiply_pos_neg  <= vcu_if.multiply_pos_neg;
      decode_execute_if.multiply_type     <= vcu_if.multiply_type;
      //new
      decode_execute_if.sew               <= sew;
      decode_execute_if.lmul              <= lmul;
      //missing arith signals
      decode_execute_if.comp_type         <= vcu_if.comp_type;
      decode_execute_if.adc_sbc           <= vcu_if.adc_sbc;
      decode_execute_if.carry_borrow_ena  <= vcu_if.carry_borrow_ena;
      decode_execute_if.carryin_ena       <= vcu_if.carryin_ena;
      decode_execute_if.rev               <= vcu_if.rev;
      decode_execute_if.ext_type          <= vcu_if.ext_type;

      decode_execute_if.woutu             <= vcu_if.woutu;
      decode_execute_if.win               <= vcu_if.win;
      decode_execute_if.zext_w            <= vcu_if.zext_w;

      decode_execute_if.vd                <= vcu_if.vd;
      decode_execute_if.single_bit_write  <= vcu_if.single_bit_op;

      decode_execute_if.vstart            <= prv_if.vstart;
      decode_execute_if.next_vtype_csr    <= (vcu_if.cfgsel == VSETIVLI) || (vcu_if.cfgsel == VSETVLI) ? {24'd0, vop_c.vma, vop_c.vta, vop_c.sew, vop_c.lmul} : decode_execute_if.xs2;
      decode_execute_if.next_avl_csr      <= (vcu_if.cfgsel == VSETIVLI) ? vcu_if.imm_5 : decode_execute_if.xs1;
      decode_execute_if.rd_data           <= '0;
      decode_execute_if.vd_widen          <= vcu_if.vd_widen;

      decode_execute_if.vs2_offset0       <= vs2_offset0;
      decode_execute_if.vs2_offset1       <= vs2_offset1;

      decode_execute_if.is_masked         <= vcu_if.vm;

      decode_execute_if.vd_narrow         <= vcu_if.vd_narrow;
      decode_execute_if.mask_type         <= vcu_if.mask_type;

      decode_execute_if.mask_32bit_lane0  <= rfv_if.mask_32bit_lane0;
      decode_execute_if.mask_32bit_lane1  <= rfv_if.mask_32bit_lane1;
      decode_execute_if.out_inv           <= vcu_if.out_inv;
      decode_execute_if.in_inv           <= vcu_if.in_inv;


      //TESTBENCH ONLY
      decode_execute_if.tb_line_num       <= fetch_decode_if.tb_line_num;

    end
  end

endmodule

