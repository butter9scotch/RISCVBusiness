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

`include "scalar_vector_decode_if.vh"
`include "rv32v_decode_execute_if.vh"
`include "rv32v_reg_file_if.vh"
`include "rv32v_hazard_unit_if.vh"
`include "prv_pipeline_if.vh"
`include "microop_buffer_if.vh"
`include "compress_offset_unit_if.vh"

module rv32v_decode_stage (
  input logic CLK, nRST, halt,
  scalar_vector_decode_if.decode scalar_vector_if,
  rv32v_decode_execute_if.decode decode_execute_if,
  rv32v_reg_file_if.decode rfv_if,
  rv32v_hazard_unit_if.decode hu_if,
  prv_pipeline_if.vdecode prv_if,
  rv32v_reorder_buffer_if.decode rob_if,
  input logic [31:0] xs1, xs2,
  input logic scalar_hazard_if_ret
);

  import rv32i_types_pkg::*;

//right now the register file is configured to have an array of read and write ports

  parameter ZERO = 0; 

  vector_control_unit_if vcu_if();
  element_counter_if ele_if();
  compress_offset_unit_if cou_if();
  // microop_buffer_if uop_if();

  vector_control_unit vcu(.*);
  element_counter  element_counter(.*);
  compress_offset_unit  compress_offset_unit(.CLK(CLK), .nRST(nRST), .cou_if(cou_if));
  // microop_buffer uop_buffer(.*);

  sew_t sew;
  width_t eew_loadstore;
  vlmul_t lmul, emul;
  logic [31:0] vstart, ls_vl, num_ele_each_reg, num_ele_each_reg1, num_ele_each_reg2, num_ele_each_reg3, num_ele_each_reg4, num_ele_each_reg5, num_ele_each_reg6, num_ele_each_reg7, total_vl_for_lsreg, nf_count_reg, next_nf_count_reg, buffered_instr, next_buffered_instr;
  logic wen0, wen1, nf_count_ena, nf_count_ena_ff1, nf_count_ena_ff2, segment_type;
  offset_t woffset0, woffset1, vs1_offset0, vs1_offset1, vs2_offset0, vs2_offset1;
  logic [4:0] new_vd;

  logic mask0, mask1;

  sew_t next_decode_execute_if_eew;

   
  //======================V_STALL LATCH===========================
  logic busy;
  assign hu_if.v_busy = busy | scalar_vector_if.v_start;
  always_ff @(posedge CLK, negedge nRST) begin : STALL_LATCH
    if (~nRST) begin
      busy <= 0; 
    end else if (hu_if.exception_v | rob_if.v_done) begin // or on flush
      busy <= 0;
    end else if (scalar_vector_if.v_start) begin
      busy <= 1;
    end
  end

  assign sew = vcu_if.sew; 
  // assign eew_loadstore = width_t'(scalar_vector_if.instr[14:12]); 
  assign lmul = vcu_if.lmul;
  assign segment_type = vcu_if.nf != '0 && (vcu_if.lumop != LUMOP_UNIT_FULLREG) & (vcu_if.is_load | vcu_if.is_store);

  // compress offset unit assigns
  assign cou_if.ena       = vcu_if.vd_offset_src == VD_SRC_COMPRESS;
  assign cou_if.done      = ele_if.done[ZERO];
  assign cou_if.vs1_mask  = rfv_if.vs1_mask[ZERO];
  assign cou_if.reset     = hu_if.csr_update;

  // Load store vl calculation to allow parallelism
  assign ls_vl = vcu_if.lumop == LUMOP_UNIT_FULLREG ? total_vl_for_lsreg :
                 vcu_if.nf != '0 ? prv_if.vl :
                 sew == SEW32 && vcu_if.eew_loadstore == WIDTH8 ? prv_if.vl >> 2 :
                 sew == SEW32 && vcu_if.eew_loadstore == WIDTH16 ? prv_if.vl >> 1 :
                 sew == SEW16 && vcu_if.eew_loadstore == WIDTH8 ? prv_if.vl >> 1 :
                 prv_if.vl;
  assign num_ele_each_reg = VLEN >> 5;
  assign num_ele_each_reg1 = num_ele_each_reg + num_ele_each_reg;
  assign num_ele_each_reg2 = num_ele_each_reg1 + num_ele_each_reg;
  assign num_ele_each_reg3 = num_ele_each_reg2 + num_ele_each_reg;
  assign num_ele_each_reg4 = num_ele_each_reg3 + num_ele_each_reg;
  assign num_ele_each_reg5 = num_ele_each_reg4 + num_ele_each_reg;
  assign num_ele_each_reg6 = num_ele_each_reg5 + num_ele_each_reg;
  assign num_ele_each_reg7 = num_ele_each_reg6 + num_ele_each_reg;
  assign nf_count_ena = ((woffset0 == ele_if.vl[ZERO] - 1) | (woffset1 == ele_if.vl[ZERO] - 1)) & (vcu_if.nf != 0) & (vcu_if.lumop != LUMOP_UNIT_FULLREG) & (vcu_if.is_load | vcu_if.is_store);
  assign next_buffered_instr = {scalar_vector_if.instr[31:12], new_vd, scalar_vector_if.instr[6:0]};
  //assign next_nf_count_reg = nf_count_ena ? nf_count_reg + 1 : nf_count_reg;
  always_comb begin // EMUL = EEW/SEW * LMUL
    case(lmul)
       LMUL1: begin
         if (sew == SEW8) begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMUL1;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL2;
           else emul = LMUL4;
         end else if (sew == SEW16) begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMULHALF; 
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL1;
           else emul = LMUL2;
         end else begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMULFOURTH;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMULHALF;
           else emul = LMUL1;
         end
       end
       LMUL2: begin
         if (sew == SEW8) begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMUL2;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL4; 
           else emul = LMUL8;
         end else if (sew == SEW16) begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMUL1;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL2;
           else emul = LMUL4;
         end else begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMULHALF;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL1;
           else emul = LMUL2;
         end
       end
       LMUL4: begin
         if (sew == SEW8) begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMUL4;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL8; 
           else emul = LMUL8;
         end else if (sew == SEW16) begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMUL2;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL4;
           else emul = LMUL8;
         end else begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMUL1;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL2;
           else emul = LMUL4;
         end
       end
       LMUL8: begin
         if (sew == SEW8) begin
           emul = LMUL8;
         end else if (sew == SEW16) begin  
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMUL4;
           else emul = LMUL8;
         end else begin
           if (vcu_if.eew_loadstore == WIDTH8) emul = LMUL2;
           else if (vcu_if.eew_loadstore == WIDTH16) emul = LMUL4;
           else emul = LMUL8;
         end
       end
       default: emul = LMUL1;
    endcase
  end

  always_comb begin
    case(emul)
       LMUL1, LMULHALF, LMULFOURTH: new_vd = scalar_vector_if.instr[11:7] + nf_count_reg; // (0, 1j, 2j ....)
       LMUL2: new_vd = scalar_vector_if.instr[11:7] + nf_count_reg + nf_count_reg; // (0, 2j, 4j ....)
       //LMUL3: new_vd = scalar_vector_if.instr[11:7] + nf_count_reg + nf_count_reg + nf_count_reg; // (0, 3j, 6j ....)
       LMUL4: new_vd = scalar_vector_if.instr[11:7] + nf_count_reg + nf_count_reg + nf_count_reg + nf_count_reg; // (0, 4j, 8j ....)
       LMUL8: new_vd = scalar_vector_if.instr[11:7] + nf_count_reg + nf_count_reg + nf_count_reg + nf_count_reg + nf_count_reg + nf_count_reg + nf_count_reg + nf_count_reg; // (0, 8j, 16j ....)
       default: new_vd = scalar_vector_if.instr;
    endcase
  end

  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      nf_count_reg <= 0;
    end else if (~hu_if.stall_dec & nf_count_reg == vcu_if.nf && nf_count_ena) begin
      nf_count_reg <= 0;
    end else if (~hu_if.stall_dec & nf_count_ena) begin
      nf_count_reg <= nf_count_reg + 1;
    end
  end
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin
      buffered_instr <= 0;
      nf_count_ena_ff2 <= '0;
    end else if (~hu_if.stall_dec & nf_count_reg == vcu_if.nf && nf_count_ena) begin
      nf_count_ena_ff2 <= 0;
    end else if (nf_count_ena_ff1) begin
      buffered_instr <= next_buffered_instr;
      nf_count_ena_ff2 <= 1; 
    end
  end
  always_ff @ (posedge CLK, negedge nRST) begin
    if (nRST == 0) begin 
      nf_count_ena_ff1 <= 0;
      //nf_count_ena_ff2 <= 0;
    end else if (~hu_if.stall_dec & nf_count_reg == vcu_if.nf && nf_count_ena) begin
      nf_count_ena_ff1 <= 0;
    end else begin
      nf_count_ena_ff1 <= nf_count_ena;
      //nf_count_ena_ff2 <= nf_count_ena_ff1;
    end
  end
  always_comb begin
    case(vcu_if.nf)
      3'd0: total_vl_for_lsreg = num_ele_each_reg;
      3'd1: total_vl_for_lsreg = num_ele_each_reg1;
      3'd2: total_vl_for_lsreg = num_ele_each_reg2;
      3'd3: total_vl_for_lsreg = num_ele_each_reg3;
      3'd4: total_vl_for_lsreg = num_ele_each_reg4;
      3'd5: total_vl_for_lsreg = num_ele_each_reg5;
      3'd6: total_vl_for_lsreg = num_ele_each_reg6;
      3'd7: total_vl_for_lsreg = num_ele_each_reg7;
      default: total_vl_for_lsreg = num_ele_each_reg;
    endcase
  end

  // vector control unit assigns
  assign vcu_if.instr = nf_count_ena_ff2 ? buffered_instr : scalar_vector_if.instr;
  assign vcu_if.vtype = prv_if.vtype;
  // element counter assigns
  assign ele_if.vstart[ZERO]    = prv_if.vstart; 
  assign ele_if.vl[ZERO]        = vcu_if.mask_logical ? 4 : 
                            			(vcu_if.is_load || vcu_if.is_store) && (vcu_if.mop == MOP_UNIT) ? ls_vl :
                            			(vcu_if.vmv_type == NOT_VMV) ? prv_if.vl : 
                            			(vcu_if.vmv_type == X_S) || (vcu_if.vmv_type == S_X) ? 1 : 
                            			(VLENB >> sew) << vcu_if.vmv_type;  
  assign ele_if.stall[ZERO]     = hu_if.busy_ex | hu_if.busy_mem;  
  assign ele_if.ex_return[ZERO] = scalar_hazard_if_ret;  //TODO: check this
  assign ele_if.start[ZERO]     = scalar_vector_if.v_start;   
  assign ele_if.clear[ZERO]     = hu_if.flush_dec | rob_if.v_done;
  assign ele_if.busy_ex[ZERO]   = hu_if.busy_ex | hu_if.busy_mem;

  logic counter_done_ff1;
  always_ff @(posedge CLK, negedge nRST) begin : DELAY_DONE_SIGNAL
    if (~nRST) begin
      counter_done_ff1 <= 0;
    end else begin
      counter_done_ff1 <= decode_execute_if.counter_done;
    end
  end

  logic [31:0] sign_ext_imm5, zero_ext_imm5;
  assign sign_ext_imm5 = {{27{vcu_if.imm_5[4]}}, vcu_if.imm_5};
  assign zero_ext_imm5 = {27'd0, vcu_if.imm_5};

  // microop buffer assigns

  assign hu_if.busy_dec = vcu_if.de_en & ~(ele_if.done[ZERO] & nf_count_reg == 0); // TODO: Editted by Jing. Check with Owen (This will save one cycle after decoding of one instr is done)
  assign rfv_if.vs2_sew[ZERO] = vcu_if.vs2_sew;

  always_comb begin : MASK_BITS 
    if (vcu_if.vs1_offset_src == NORMAL) begin
      mask0 = ~vcu_if.vm ? rfv_if.vs1_mask[ZERO][0] : 1;
      mask1 = ~vcu_if.vm ? rfv_if.vs1_mask[ZERO][1] : 1;
    end else if (vcu_if.vs2_offset_src == NORMAL) begin
      mask0 = ~vcu_if.vm ? rfv_if.vs2_mask[ZERO][0] : 1;
      mask1 = ~vcu_if.vm ? rfv_if.vs2_mask[ZERO][1] : 1;
    end else begin
      mask0 = ~vcu_if.vm ? rfv_if.vs3_mask[ZERO][0] : 1;
      mask1 = ~vcu_if.vm ? rfv_if.vs3_mask[ZERO][1] : 1;
    end
  end

  always_comb begin
    if (prv_if.vstart >= prv_if.vl) begin
      wen0 = 0;
      wen1 = 0;
    end else if (vcu_if.reduction_ena) begin
      wen0 = ele_if.next_done[ZERO];
      wen1 = 0;
    end else if (cou_if.ena) begin
      wen0 = cou_if.wen[0];
      wen1 = cou_if.wen[1];
    end else if (vcu_if.is_store) begin
      wen0 = 0;
      wen1 = 0;
    end else if (vcu_if.is_load) begin
      wen0 = vcu_if.wen & mask0;
      wen1 = vcu_if.wen & mask1;
    end else begin
      wen0 = (vcu_if.result_type == A_S) ? 1 : vcu_if.wen & (mask0);
      wen1 = (vcu_if.result_type == A_S) ? 1: vcu_if.wen & (mask1);
    end
  end

  always_comb begin : VS1_OFFSET
    case(vcu_if.vs1_offset_src)
    VS1_SRC_NORMAL: begin 
            vs1_offset0 = ele_if.offset[ZERO];
            vs1_offset1 = ele_if.offset[ZERO] + 1;
    end
    VS1_SRC_ZERO: begin
            vs1_offset0 = 0;
            vs1_offset1 = 0;
    end
    default: begin
            vs1_offset0 = ele_if.offset;
            vs1_offset1 = ele_if.offset + 1;
    end
  endcase
  end

  always_comb begin : VS2_OFFSET
    case(vcu_if.vs2_offset_src)
      VS2_SRC_NORMAL: begin 
              vs2_offset0 = ele_if.offset[ZERO];
              vs2_offset1 = ele_if.offset[ZERO] + 1;
      end
      VS2_SRC_IDX_PLUS_RS1: begin 
              vs2_offset0 = ele_if.offset[ZERO] + xs1;
              vs2_offset1 = ele_if.offset[ZERO] + xs1 + 1;
      end
      VS2_SRC_IDX_PLUS_UIMM: begin 
            vs2_offset0 = ele_if.offset[ZERO] + zero_ext_imm5;
            vs2_offset1 = ele_if.offset[ZERO] + zero_ext_imm5 + 1;
      end
      VS2_SRC_IDX_PLUS_1: begin 
            vs2_offset0 = ele_if.offset[ZERO] + 1;
            vs2_offset1 = ele_if.offset[ZERO] + 2; 
      end
      VS2_SRC_IDX_MINUS_1: begin 
            vs2_offset0 = ele_if.offset[ZERO] - 1;
            vs2_offset1 = ele_if.offset[ZERO]; 
      end
      VS2_SRC_VS1: begin 
            vs2_offset0 = rfv_if.vs1_data[ZERO][0];
            vs2_offset1 = rfv_if.vs1_data[ZERO][1];
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
      default: begin
            vs2_offset0 = ele_if.offset;
            vs2_offset1 = ele_if.offset + 1;
      end
    endcase
  end

  always_comb begin : WOFFSET
    case (vcu_if.vd_offset_src)
      VD_SRC_NORMAL: begin   
        woffset0 = ele_if.offset[ZERO];
        woffset1 = ele_if.offset[ZERO] + 1;
      end       
      VD_SRC_ZERO: begin   
        woffset0 = 0;
        woffset1 = 0;
      end         
      VD_SRC_IDX_PLUS_RS1:  begin  
        woffset0 = ele_if.offset[ZERO] + xs1;
        woffset1 = ele_if.offset[ZERO] + xs1 + 1;
      end
      VD_SRC_IDX_PLUS_UIMM: begin  
        woffset0 = ele_if.offset[ZERO] + zero_ext_imm5;
        woffset1 = ele_if.offset[ZERO] + zero_ext_imm5 + 1;
      end
      VD_SRC_IDX_PLUS_1:  begin  
        woffset0 = ele_if.offset[ZERO] + 1;
        woffset1 = ele_if.offset[ZERO] + 2;
      end         
      VD_SRC_COMPRESS: begin   
        //woffset0 = ele_if.offset;      //this will need to change 
        //woffset1 = ele_if.offset + 1; //this will need to change
        woffset0 = cou_if.woffset0;
        woffset1 = cou_if.woffset1;
      end
      default: begin
        woffset0 = ele_if.offset;
        woffset1 = ele_if.offset + 1;
      end
    endcase
  end

  //======================REGFILE INPUTS===========================
  assign rfv_if.vs1[ZERO]             = vcu_if.vs1;
  assign rfv_if.vs2[ZERO]             = vcu_if.vs2;
  assign rfv_if.vs3[ZERO]             = vcu_if.vd;
  assign rfv_if.vs1_offset[ZERO][0]   = vs1_offset0;
  assign rfv_if.vs1_offset[ZERO][1]   = vs1_offset1;
  assign rfv_if.vs2_offset[ZERO][0]   = vs2_offset0;
  assign rfv_if.vs2_offset[ZERO][1]   = vs2_offset1;
  assign rfv_if.vs3_offset[ZERO][0]   = woffset0; // use offset of vd here because same bits in instruction
  assign rfv_if.vs3_offset[ZERO][1]   = woffset1; // use offset of vd here because same bits in instruction
  assign rfv_if.sew[ZERO] = (vcu_if.is_store || vcu_if.is_load) ? vcu_if.eew : vcu_if.sew;

  // assign rfv_if.vl = prv_if.vl;
  // assign rfv_if.vs2_sew = vcu_if.vs2_widen ? (prv_if.sew == SEW32) || (prv_if.sew == SEW16) ? SEW32 :
                                              // (prv_if.sew == SEW8) ? SEW16 : prv_if.sew;
  assign hu_if.decode_ena = vcu_if.de_en;
  assign hu_if.v_decode_done = ele_if.done[ZERO];



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
      decode_execute_if.load_ena          <= '0;
      decode_execute_if.store_ena         <= '0;
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
      decode_execute_if.vd_widen          <= '0;

      decode_execute_if.vs2_offset0       <= '0;
      decode_execute_if.vs2_offset1       <= '0;

      decode_execute_if.is_masked         <= '0;
      decode_execute_if.vd_narrow         <= '0;

      decode_execute_if.mask_type         <= '0;

      decode_execute_if.mask_32bit_lane0  <= '0;
      decode_execute_if.mask_32bit_lane1  <= '0;
      decode_execute_if.decode_done       <= '0;
      decode_execute_if.rd_scalar_src     <= '0;

      decode_execute_if.nf                <= '0;
      decode_execute_if.eew_loadstore     <= '0;
      decode_execute_if.lumop             <= '0;
      decode_execute_if.vmv_type          <= NOT_VMV;
      decode_execute_if.segment_type      <= '0;
      decode_execute_if.ena               <= '0;
      decode_execute_if.index             <= '0;
      decode_execute_if.counter_done      <= '0;

    end else if(hu_if.flush_dec | (counter_done_ff1 & ~hu_if.stall_dec)) begin
      decode_execute_if.stride_type       <= '0;
      decode_execute_if.rd_wen            <= '0;
      decode_execute_if.config_type       <= '0;
      decode_execute_if.mask0             <= '0;
      decode_execute_if.mask1             <= '0;
      decode_execute_if.reduction_ena     <= '0;
      decode_execute_if.is_signed         <= '0;
      decode_execute_if.ls_idx            <= '0;
      decode_execute_if.load_ena          <= '0;
      decode_execute_if.store_ena         <= '0;
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
      decode_execute_if.rd_data           <= '0;
      decode_execute_if.vd_widen          <= '0;

      decode_execute_if.vs2_offset0       <= '0;
      decode_execute_if.vs2_offset1       <= '0;

      decode_execute_if.is_masked         <= '0;

      decode_execute_if.vd_narrow         <= '0;

      decode_execute_if.mask_type         <= '0;
      decode_execute_if.mask_32bit_lane0  <= '0;
      decode_execute_if.mask_32bit_lane1  <= '0;
      decode_execute_if.decode_done       <= '0;
      decode_execute_if.rd_scalar_src     <= '0;

      decode_execute_if.nf                <= '0;
      decode_execute_if.eew_loadstore     <= '0;
      decode_execute_if.lumop             <= '0;
      decode_execute_if.vmv_type          <= NOT_VMV;
      decode_execute_if.segment_type      <= '0;

      decode_execute_if.ena               <= '0;
      decode_execute_if.index             <= scalar_vector_if.index;
      decode_execute_if.counter_done      <= ele_if.done[ZERO];

    end else if (~hu_if.stall_dec & ~counter_done_ff1) begin
      decode_execute_if.rd_wen            <= vcu_if.rd_scalar_src; //write to scalar regs
      decode_execute_if.rd_sel            <= vcu_if.vd;
      decode_execute_if.rd_data           <= vcu_if.rd_scalar_src ? rfv_if.vs2_data[ZERO][0] : 32'hDEAD;

      decode_execute_if.stride_type       <= vcu_if.stride_type;
      decode_execute_if.config_type       <= vcu_if.cfgsel;
      decode_execute_if.fu_type           <= vcu_if.fu_type;
      decode_execute_if.result_type       <= vcu_if.result_type;
      decode_execute_if.minmax_type       <= vcu_if.minmax_type;
      decode_execute_if.comp_type         <= vcu_if.comp_type;
      decode_execute_if.ext_type          <= vcu_if.ext_type;


      decode_execute_if.ls_idx            <= vcu_if.ls_idx;
      decode_execute_if.load_ena          <= vcu_if.is_load;
      decode_execute_if.store_ena         <= vcu_if.is_store;
      decode_execute_if.stride_val        <= xs2; //from xs2 field in instr; 
      decode_execute_if.reduction_ena     <= vcu_if.reduction_ena; 
      
      //======================REGFILE DATA===========================
      decode_execute_if.mask0             <= mask0; 
      decode_execute_if.mask1             <= mask1; 

      decode_execute_if.vs1_lane0         <=  vcu_if.vmv_type == S_X ? xs1 : rfv_if.vs1_data[ZERO];
      decode_execute_if.vs2_lane0         <=  vcu_if.vd_narrow & (sew == SEW32) ? {16'd0, rfv_if.vs2_data[ZERO][0][15:0]} : 
                                              vcu_if.vd_narrow & (sew == SEW16) ? {24'd0, rfv_if.vs2_data[ZERO][0][7:0]} : 
                                              vcu_if.vs2_offset_src == VS2_SRC_IDX_MINUS_1 & (vs2_offset1 == prv_if.vstart) ? xs1 : 
                                              vcu_if.vs2_offset_src == VS2_SRC_IDX_PLUS_1 & (vs2_offset0 == prv_if.vl) ? xs1 : 
                                              rfv_if.vs2_data[ZERO][0];
      decode_execute_if.vs3_lane0         <=  rfv_if.vs3_data[ZERO][0];

      decode_execute_if.vs1_lane1         <=  rfv_if.vs1_data[ZERO][1]; 
      decode_execute_if.vs2_lane1         <=  vcu_if.vd_narrow & (sew == SEW32) ? {16'd0, rfv_if.vs2_data[ZERO][1][15:0]} : 
                                              vcu_if.vd_narrow & (sew == SEW16) ? {24'd0, rfv_if.vs2_data[ZERO][1][7:0]} : 
                                              vcu_if.vs2_offset_src == VS2_SRC_IDX_PLUS_1 & (vs2_offset1 == prv_if.vl) ? xs1 : 
                                              rfv_if.vs2_data[ZERO][1];
      decode_execute_if.vs3_lane1         <=  rfv_if.vs3_data[ZERO][1];
      
      //======================STORE UNIT===========================
      decode_execute_if.storedata0        <= rfv_if.vs3_data[ZERO][0];
      decode_execute_if.storedata1        <= rfv_if.vs3_data[ZERO][1];
      
      //======================WRITE DATA===========================
      decode_execute_if.woffset0          <=  woffset0; 
      decode_execute_if.woffset1          <=  woffset1; 
      decode_execute_if.vd                <= vcu_if.vd;
      decode_execute_if.single_bit_write  <= vcu_if.single_bit_op;
      decode_execute_if.wen[0]            <= vcu_if.merge_ena | wen0;
      decode_execute_if.wen[1]            <= vcu_if.merge_ena | wen1;
      decode_execute_if.vd_widen          <= vcu_if.vd_widen;
      decode_execute_if.vd_narrow         <= vcu_if.vd_narrow;



      //======================TYPE SIGNALS===========================
      decode_execute_if.rs1_type          <= vcu_if.rs1_type;
      decode_execute_if.rs2_type          <= vcu_if.rs2_type;
      decode_execute_if.vmv_type          <= vcu_if.vmv_type;
      
      //======================DIV SIGNALS===========================
      decode_execute_if.div_type          <= vcu_if.div_type;
      decode_execute_if.is_signed_div     <= vcu_if.is_signed == SIGNED;

      //======================MUL SIGNALS===========================
      decode_execute_if.high_low          <= vcu_if.high_low;
      decode_execute_if.is_signed_mul     <= vcu_if.is_signed;
      decode_execute_if.mul_widen_ena     <= vcu_if.mul_widen_ena;
      decode_execute_if.multiply_pos_neg  <= vcu_if.multiply_pos_neg;
      decode_execute_if.multiply_type     <= vcu_if.multiply_type;
      //new

      //======================INSTR SIGNALS===========================
      decode_execute_if.xs1               <= xs1; 
      decode_execute_if.xs2               <= xs2; 
      decode_execute_if.imm               <= vcu_if.sign_extend ? sign_ext_imm5 : zero_ext_imm5; // sign extend, i think this works

      //======================CONFIG SIGNALS===========================
      decode_execute_if.sew               <= sew;
      decode_execute_if.lmul              <= lmul;
      decode_execute_if.eew               <= vcu_if.eew; 
      decode_execute_if.vl                <= (vcu_if.is_load || vcu_if.is_store) && (vcu_if.mop == MOP_UNIT) ? ls_vl :
                                             (vcu_if.vmv_type == NOT_VMV) ? prv_if.vl : 
                                             (vcu_if.vmv_type == X_S) || (vcu_if.vmv_type == S_X) ? 1 : 
                                              (VLENB >> sew) << vcu_if.vmv_type; 
      decode_execute_if.vlenb             <= prv_if.vlenb;   
      decode_execute_if.vtype             <= prv_if.vtype;   
      decode_execute_if.vstart            <= prv_if.vstart;
      

      //======================ARITH SIGNALS===========================
      decode_execute_if.aluop             <= vcu_if.aluop;
      decode_execute_if.adc_sbc           <= vcu_if.adc_sbc;
      decode_execute_if.carry_borrow_ena  <= vcu_if.carry_borrow_ena;
      decode_execute_if.carryin_ena       <= vcu_if.carryin_ena;
      decode_execute_if.rev               <= vcu_if.rev;

      decode_execute_if.woutu             <= vcu_if.woutu;
      decode_execute_if.win               <= vcu_if.win;
      decode_execute_if.zext_w            <= vcu_if.zext_w;

      decode_execute_if.vs2_offset0       <= vs2_offset0;
      decode_execute_if.vs2_offset1       <= vs2_offset1;

      decode_execute_if.is_masked         <= vcu_if.vm;

      decode_execute_if.mask_type         <= vcu_if.mask_type;

      decode_execute_if.mask_32bit_lane0  <= rfv_if.mask_32bit_lane0;
      decode_execute_if.mask_32bit_lane1  <= rfv_if.mask_32bit_lane1;
      decode_execute_if.decode_done       <= ele_if.done[ZERO];
      decode_execute_if.is_signed         <= vcu_if.is_signed;

      decode_execute_if.nf                <= vcu_if.nf;
      decode_execute_if.eew_loadstore     <= vcu_if.eew_loadstore;
      decode_execute_if.lumop             <= vcu_if.lumop;
      decode_execute_if.rd_scalar_src     <= vcu_if.rd_scalar_src;
      decode_execute_if.nf_count          <= nf_count_reg;
      decode_execute_if.segment_type      <= segment_type;
      decode_execute_if.ena               <= vcu_if.de_en;
      decode_execute_if.valid             <= ele_if.active[ZERO];
      // ROB signals
      decode_execute_if.index             <= scalar_vector_if.index;
      decode_execute_if.counter_done      <= ele_if.done[ZERO];

    end
  end

endmodule

