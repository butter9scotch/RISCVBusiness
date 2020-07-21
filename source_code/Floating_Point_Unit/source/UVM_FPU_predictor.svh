import uvm_pkg::*;
`include "uvm_macros.svh"

`include "FPU_if.svh"
`include "FPU_transaction.svh"

class FPU_predictor extends uvm_subscriber #(FPU_transaction);
  `uvm_component_utils(FPU_predictor) 
 
  registerFile sim_rf;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void write(FPU_transaction tx);
    localparam ADD = 7'b0100000;
    localparam MUL = 7'b0000010;
    localparam SUB = 7'b0100100;
    real real_val1; //first real operand
    real real_val2; //second real operand
    real real_result; //result of the operation
    logic [31:0] fp_result;
    logic [31:0] fp1;
    logic [31:0] fp2;

    fp1 = sim_rf.read(tx.f_rs1);
    fp2 = sim_rf.read(tx.f_rs2);

    if(tx.funct7 == ADD) begin
      real_val1 = fp_to_real(fp1);
      real_val2 = fp_to_real(fp2);
      real_result = real_val1 + real_val2;
      fp_result = real_to_fp(real_result);
      sim_rf.write(tx.f_rd, fp_result);
    end else if (tx.funct7 == MUL) begin
      real_val1 = fp_to_real(fp1);
      real_val2 = fp_to_real(fp2);
      real_result = real_val1 * real_val2;
      fp_result = real_to_fp(real_result);
      sim_rf.write(tx.f_rd, fp_result);
    end else if (tx.funct7 == SUB) begin
      real_val1 = fp_to_real(fp1);
      real_val2 = fp_to_real(fp2);
      real_result = real_val1 - real_val2;
      fp_result = real_to_fp(real_result);
      sim_rf.write(tx.f_rd, fp_result);
    end
  endfunction: write

  // conversion function copied directly from the previous test bench
  // input: val   -   32bit floating point value according to IEEE 754
  // output: fp   -   converted value in real
  function real fp_to_real(logic [31:0] val);
    real fp;
    real fp_exp;
    real fp_frac;
    fp_exp  = real'(val[30:23]);
    fp_frac = real'(val[22:0]);

    fp_exp = fp_exp - 128;
	 
    for(int k = 0; k < 23; k = k + 1) begin
        fp_frac /= 2;
    end
    fp_frac = fp_frac + 1;	 

	  if(val[31]) 
	   fp = -fp_frac * (2 ** fp_exp);
	  else
	   fp = fp_frac * (2 ** fp_exp);
    return fp;
  endfunction

  // conversion function copied directly from the previous test bench
  // input: r     -   real deciaml value
  // output: fp   -   converted 32 bit floating point value specified by IEEE 754
  function logic [31:0] real_to_fp(real r);
    logic [31:0] fp;
    int fp_index;
	  real MAX;
	  real MIN;
	 
    MAX = fp_to_real(32'b01111111011111111111111111111111);
    MIN = fp_to_real(32'b00000000000000000000000000000000);
	 
	  fp = 32'b01000000000000000000000000000000;

    if(r < 0) begin // set sign bit
      fp[31] = 1'b1;
      r = -r;
    end
	 
    if(r < MIN) // ovf 
      fp[30:0] = 31'b0000000000000000000000000000000;

    else if(r > MAX) // unf
      fp[30:0] = 31'b1111111100000000000000000000000;
    
    else begin // everything else
	    if(r >= 2) begin 
        while(r >= 2) begin
          r /= 2;
		      fp[30:23] += 1;
        end
	    end
	    else if(r < 1) begin
        while(r < 1) begin
          r *= 2;
          fp[30:23] -= 1;
        end
	    end
	    
	    r -= 1;
	    fp_index = 22;
	    for(real i = 0.50; i != 2**-24; i /= 2) begin
	       if(r >= i) begin
		  r -= i;
		  fp[fp_index] = 1'b1;
	       end
	       fp_index -= 1;
	    end
	  end // else: !if((r>(1.70141*(10**38))))
    return fp;
  endfunction

endclass: FPU_predictor


class registerFile;
  parameter NUM_REGS = 32;
  logic [31:0] [NUM_REGS-1:0] registers;
  function new();
    
  endfunction //new()

  function write(logic[4:0]rd, logic[31:0] val);
    registers[rd] = val;
  endfunction

  function logic[31:0] read(logic[4:0]rd);
    return registers[rd]
  endfunction

endclass //registerFile
