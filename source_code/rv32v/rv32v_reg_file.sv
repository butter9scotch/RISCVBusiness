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
*   Filename:     src/rv32v_reg_file.sv
*
*   Created by:   Owen Prince	
*   Email:        oprince@purdue.edu
*   Date Created: 10/10/2021
*   Description:   Vector Register File
*/

`include "rv32v_reg_file_if.vh"

module rv32v_reg_file # (
  parameter LANES=2,
  parameter READ_PORTS=1,
  parameter WRITE_PORTS=1
) (
  input CLK, nRST,
  rv32v_reg_file_if.rf rfv_if
);

  // import rv32i_types_pkg::*;
  import rv32i_types_pkg::*;


  parameter NUM_REGS = 32;
  parameter MAXLEN = NUM_REGS * 8;

  // logic [6:0] vd1_start, vd2_start;
  // logic [6:0] vd1_end, vd2_end;
  // `ifdef TESTBENCH
  logic tb_ctrl;
  logic [4:0] tb_sel;
  logic [127:0] tb_data;
  // `endif

  logic     [LANES-1:0][2:0]    vs1_inner_offset;
  logic     [LANES-1:0][2:0]    vs2_inner_offset;
  logic     [LANES-1:0][2:0]    vs3_inner_offset;

  logic     [LANES-1:0][3:0]    vs1_outer_offset;
  logic     [LANES-1:0][3:0]    vs2_outer_offset;
  logic     [LANES-1:0][3:0]    vs3_outer_offset;

  offset_t  [LANES-1:0]         vs1_offset_lane;
  offset_t  [LANES-1:0]         vs2_offset_lane;
  offset_t  [LANES-1:0]         vs3_offset_lane;

  logic     [LANES-1:0][2:0]    vd_inner_offset;
  logic     [LANES-1:0][3:0]    vd_outer_offset;  
  offset_t  [LANES-1:0]         vd_offset_lane;
  // set lower 2 bits to zero to round down instead of division

  vreg_t [NUM_REGS-1:0] registers, next_registers;

  always_ff @ (posedge CLK, negedge nRST) begin
    if (~nRST) begin
      registers <= '0;
    end else begin
      registers <= next_registers;
    end
  end 



  integer i;
  int windex, rdindex;
  assign windex = 0;
  assign rdindex = 0;
  always_comb begin
    for (i = 0; i < LANES; i = i + 1) begin

      vd_offset_lane[i]  = rfv_if.vd_offset[0][i];
      vs1_offset_lane[i] = rfv_if.vs1_offset[0][i];
      vs2_offset_lane[i] = rfv_if.vs2_offset[0][i];
      vs3_offset_lane[i] = rfv_if.vs3_offset[0][i];
      //==============================================
      //==================INNER OFFSET================
      //=======================VD=====================
      case (rfv_if.eew[windex])
        SEW32:   vd_inner_offset[i] = vd_offset_lane[i][4:2];
        SEW16:   vd_inner_offset[i] = vd_offset_lane[i][5:3];
        default: vd_inner_offset[i] = vd_offset_lane[i][6:4];
      endcase
      //=======================VS1,VS3=====================
      case (rfv_if.sew[rdindex])
        SEW32: begin   
          vs1_inner_offset[i] = vs1_offset_lane[i][4:2];
          vs3_inner_offset[i] = vs3_offset_lane[i][4:2];
        end
        SEW16: begin  
          vs1_inner_offset[i] = vs1_offset_lane[i][5:3];
          vs3_inner_offset[i] = vs3_offset_lane[i][5:3];
        end
        default: begin
          vs1_inner_offset[i] = vs1_offset_lane[i][6:4];
          vs3_inner_offset[i] = vs3_offset_lane[i][6:4];
        end
      endcase
      //=======================VS2=====================
      case (rfv_if.vs2_sew[rdindex])
        SEW32:   vs2_inner_offset[i] = vs2_offset_lane[i][4:2];
        SEW16:   vs2_inner_offset[i] = vs2_offset_lane[i][5:3];
        default: vs2_inner_offset[i] = vs2_offset_lane[i][6:4];
      endcase
      //==============================================
      //==================OUTER OFFSET================
      //======================VD======================
      case (rfv_if.eew[windex])
        SEW32:   vd_outer_offset[i] = {vd_offset_lane[i][1:0], 2'b00};
        SEW16:   vd_outer_offset[i] = {vd_offset_lane[i][2:0], 1'b0};
        default: vd_outer_offset[i] =  vd_offset_lane[i][3:0];
      endcase
      //====================VS1,VS3===================
      case (rfv_if.sew[rdindex])
        SEW32:   begin
          vs1_outer_offset[i] = {vs1_offset_lane[i][1:0], 2'b00} ; 
          vs3_outer_offset[i] = {vs3_offset_lane[i][1:0], 2'b00} ; 
        end
        SEW16:   begin
          vs1_outer_offset[i] = {vs1_offset_lane[i][2:0], 1'b00} ;
          vs3_outer_offset[i] = {vs3_offset_lane[i][2:0], 1'b00} ; 
        end
        default: begin
          vs1_outer_offset[i] =  vs1_offset_lane[i][3:0];
          vs3_outer_offset[i] =  vs3_offset_lane[i][3:0];
        end
      endcase
      //=======================VS2=====================
      case (rfv_if.vs2_sew[rdindex])
        SEW32:   vs2_outer_offset[i] = {vs2_offset_lane[i][1:0], 2'b00}; 
        SEW16:   vs2_outer_offset[i] = {vs2_offset_lane[i][2:0], 1'b00}; 
        default: vs2_outer_offset[i] =  vs2_offset_lane[i][3:0];
      endcase
    end
  end

  integer j;
  always_comb begin : WRITE_DATA
    next_registers = registers;
    for (j = 0; j < LANES; j = j + 1) begin
      //=======================SINGLE BIT WRITE====================
      if (rfv_if.single_bit_write[windex]) begin : SINGLE_BIT
        if (rfv_if.wen[windex][j] && vd_offset_lane[j] < rfv_if.vl[windex]) begin
          next_registers[rfv_if.vd[windex]][vd_offset_lane[j] >> 3][vd_offset_lane[j][2:0]] = rfv_if.w_data[windex][j][0];
        end
      end else begin
        case (rfv_if.eew)
        //=======================WRITE, SEW32====================
          SEW32: begin 
            if (rfv_if.wen[windex][j] && vd_offset_lane[j] < rfv_if.vl[windex]) begin
              next_registers[rfv_if.vd[windex] + vd_inner_offset[j]][vd_outer_offset[j]+:4] = rfv_if.w_data[windex][j][31:0];
            end
          end
        //=======================WRITE, SEW16====================
          SEW16: begin 
            if (rfv_if.wen[windex][j] && vd_offset_lane[j] < rfv_if.vl[windex]) begin
              next_registers[rfv_if.vd[windex] + vd_inner_offset[j]][vd_outer_offset[j] +:2] = rfv_if.w_data[windex][j][15:0]; 
            end
          end
        //=======================WRITE, SEW8====================
          SEW8: begin
            if (rfv_if.wen[windex][j] && vd_offset_lane[j] < rfv_if.vl[windex]) begin
              next_registers[rfv_if.vd[windex] + vd_inner_offset[j]][vd_outer_offset[j]]  = rfv_if.w_data[windex][j][7:0]; 
            end
          end
        endcase
      end
    end

    // `ifdef TESTBENCH
      if (tb_ctrl) begin next_registers[tb_sel][15:0] = tb_data; end 
    // `endif
  end


  integer i1;
  always_comb begin : VS1_DATA
    for (i1 = 0; i1 < LANES; i1 = i1 + 1) begin
      //=======================DATA====================
      //======================VS1,VS3==================
      case (rfv_if.sew[rdindex])
        SEW32: begin
          rfv_if.vs1_data[rdindex][i1] = registers[rfv_if.vs1[rdindex] + vs1_inner_offset[i1]][vs1_outer_offset[i1] +:4];
          rfv_if.vs3_data[rdindex][i1] = registers[rfv_if.vs3[rdindex] + vs3_inner_offset[i1]][vs3_outer_offset[i1] +:4];
        end 
        SEW16: begin
          rfv_if.vs1_data[rdindex][i1] = {16'h0, registers[rfv_if.vs1[rdindex] + vs1_inner_offset[i1]][vs1_outer_offset[i1] +:2]};
          rfv_if.vs3_data[rdindex][i1] = {16'h0, registers[rfv_if.vs3[rdindex] + vs3_inner_offset[i1]][vs3_outer_offset[i1] +:2]};
        end
        SEW8: begin
          rfv_if.vs1_data[rdindex][i1] = {24'h0, registers[rfv_if.vs1[rdindex] + vs1_inner_offset[i1]][vs1_outer_offset[i1]]};
          rfv_if.vs3_data[rdindex][i1] = {24'h0, registers[rfv_if.vs3[rdindex] + vs3_inner_offset[i1]][vs3_outer_offset[i1]]};
        end
        default: begin
          rfv_if.vs1_data[rdindex][i1] = 32'hDED0DED0;
          rfv_if.vs3_data[rdindex][i1] = 32'hDED0DED0;
        end
      endcase
      //======================VS2======================
      case (rfv_if.vs2_sew[rdindex])
        SEW32: begin
          rfv_if.vs2_data[rdindex][i1] = registers[rfv_if.vs2[rdindex] + vs2_inner_offset[i1]][vs2_outer_offset[i1] +:4];
        end 
        SEW16: begin
          rfv_if.vs2_data[rdindex][i1] = {16'h0, registers[rfv_if.vs2[rdindex] + vs2_inner_offset[i1]][vs2_outer_offset[i1] +:2]};
        end
        SEW8: begin
          rfv_if.vs2_data[rdindex][i1] = {24'h0, registers[rfv_if.vs2[rdindex] + vs2_inner_offset[i1]][vs2_outer_offset[i1]]};
        end
        default: begin
          rfv_if.vs2_data[rdindex][i1] = 32'hDED0DED0;
        end
      endcase
      //======================MASK BITS======================
      rfv_if.vs1_mask[rdindex][i1] = registers[i1][vs1_offset_lane[i1] >> 3][vs1_offset_lane[i1] [2:0]];
      rfv_if.vs2_mask[rdindex][i1] = registers[i1][vs2_offset_lane[i1] >> 3][vs2_offset_lane[i1] [2:0]];
      rfv_if.vs3_mask[rdindex][i1] = registers[i1][vs3_offset_lane[i1] >> 3][vs3_offset_lane[i1] [2:0]];
    end // for (i1 = 0; i1 < LANES; i1 = i1 + 1)
  end


  always_comb begin : MASK_32BIT
    rfv_if.mask_32bit_lane0 = registers[0] [vs2_outer_offset[0] +:4];
    rfv_if.mask_32bit_lane1 = registers[0][(vs2_outer_offset[0] + 1) +:4];
  end



endmodule
