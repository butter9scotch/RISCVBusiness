/*   Copyright 2016 Purdue University
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
*   Filename:     f_register_file.sv
*   
*   Created by:   Sean Hsu	
*   Email:        hsu151@purdue.edu
*   Date Created: 02/24/2020
*   Description:  floating point register file for the FPU; based on integer reg file
*/
//Modified by Xinlue Liu, Zhengsen Fu
//Last Updated  : 7/21/20

//`include "f_register_file_if.vh"
//`include "FPU_if.svh"
`include "register_FPU_if.svh"
module f_register_file (
  // input CLK, nRST,
  // FPU_if.fp fpa_if,
  // register_FPU_if.fp frf_fp
  register_FPU_if.rf frf_rf
);

//  import rv32i_types_pkg::*;

// rs1 and rs2: register locations of two calculation operands
// rd: register location where f_w_data goes

  parameter NUM_REGS = 32;

  logic [31:0] fcsr_reg;
  logic [31:0] [NUM_REGS-1:0] registers;
  logic f_wen; //write enable. Enable register file to written by FPU TODO: implementation of this signal
  //logic [2:0] frm;

  always_ff @ (posedge frf_rf.clk, negedge frf_rf.n_rst) begin
    if (~frf_rf.n_rst) begin
      fcsr_reg <= '0;
      registers <= '0;
      frf_rf.frm <= '0;
    end else if (f_wen && (!frf_rf.f_SW)) begin 
      registers[frf_rf.f_rd] <= frf_rf.f_w_data; //f_w_data: FPU_out or dload_ext
      //frf_rf.frm <= frf_rf.f_frm_in;
      fcsr_reg[7:5] <= frf_rf.f_frm_in;
      fcsr_reg[4:0] <= frf_rf.flags;
    end else begin
      //frf_rf.frm <= frf_rf.f_frm_in;
      fcsr_reg[7:5] <= frf_rf.f_frm_in;
    end
  end 

  always_comb begin: f_wen_logic
	f_wen = 1'b0; //f_wen default to be 0.
	if (frf_rf.f_LW) // if f_lw is assert(choosing dload_ext)
		f_wen = 1'b1; 
	else begin //if f_lw is asserteds(choosing FPU_out)
		if (!frf_rf.f_ready) //if not f_ready,
			f_wen = 1'b0;
		else	      //if f_ready,
			f_wen = 1'b1;
	end
  end

  assign frf_rf.f_rs1_data = registers[frf_rf.f_rs1];
  assign frf_rf.f_rs2_data = registers[frf_rf.f_rs2];

  assign frf_rf.f_frm_out = frf_rf.frm;
  // assign frf_rf.f_flags = {frf_rf.f_NV, frf_rf.f_DZ, frf_rf.f_OF, frf_rf.f_UF, frf_rf.f_NX};
  assign frf_rf.f_flags = fcsr_reg[4:0];

endmodule
