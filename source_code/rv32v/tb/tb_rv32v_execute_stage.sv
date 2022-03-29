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
/*
// `include "vector_control_unit_if.vh"
`include "instruction.svh"

module tb_vector_control_unit ();
  // import rv32i_types_pkg::*;
  import rv32i_types_pkg::*;

  int testnum;
  string testname = "";
 
  logic error_found;
  logic CLK, nRST;
  vopm_t op;

  vector_control_unit_if vcu_if();

  vector_control_unit DUT (.vcu_if(vcu_if));
    // .rfv_if(CLK, nRST, rfv_if)
  // );

  initial begin : CLK_INIT
    CLK = 1'b0;
    nRST = 1;
  end : CLK_INIT

  always begin : CLK_GEN
    #(PERIOD/2) CLK = ~CLK;
  end : CLK_GEN
 
  task reset;
    @(negedge CLK);
    nRST = 0;
    @(posedge CLK);
    nRST = 1;
  endtask

  // task writeOutputs;
  //   instruction tx;
  //   int fd;
  //   tx.randomize();
  //   fd = $fopen("./vector_control_unit_out.csv", "w");
  //   $fdisplay(fd, "Instr %d: %s", testnum, DUT.op_decoded.name());
  //   $fclose(fd);
  // endtask

  task testVectorInstrs;
    input bit [5:0] funct6;
    input bit vm;
    input bit [2:0] funct3;
    randinstruction tx = new;
    tx.vm = vm;
    tx.vfunct6_vopi = vopi_t'(funct6);
    tx.vfunct6_vopm = vopm_t'(funct6);
    tx.vfunct3 = vfunct3_t'(funct3);
    tx.randomize();
    vcu_if.instr = tx.get_instr();
    $write("%d: %s, instr = %8x\n", testnum, DUT.op_decoded.name() , tx.get_instr());
    testnum+=1;
  endtask

  bit [9:0] bitarray;
  initial begin : MAIN
    testnum = 0;
    testname = "";
    error_found = 0;

  for (bitarray = 0; bitarray < 512; bitarray++) begin
    testVectorInstrs(bitarray[8:4], bitarray[3], bitarray[2:0]);
    #(1);
  end  

    
    // op = VWMACCSU;
    // if (op inside {VWMACCSU, VWMACCUS}) $write("\n\n\n\nSUCCESS\n\n\n\n");

    $finish;
  end : MAIN
endmodule
*/
