import uvm_pkg::*;
`include "uvm_macros.svh"

`include "FPU_if.svh"
`include "FPU_transaction.svh"

class FPU_predictor extends uvm_subscriber #(FPU_transaction);
  `uvm_component_utils(FPU_predictor) 

  uvm_analysis_port #(FPU_transaction) ap_pred;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    ap_pred = new("ap_pred", this);
  endfunction

  function void write(FPU_transaction t);
    localparam ADD = 7'b0100000;
    localparam MUL = 7'b0000010;
    localparam SUB = 7'b0100100;
    FPU_transaction output_tx; //output transaction to be written to analysis port
    real real_val1; //first real operand
    real real_val2; //second real operand
    real real_result; //result of the operation
    logic [31:0] fp_result;
    output_tx = FPU_transaction::type_id::create("output_tx", this);
    // TODO:flags and output transaction
    if(t.funct7 == ADD) begin
      real_val1 = fp_to_real(t.fp1);
      real_val2 = fp_to_real(t.fp2);
      real_result = real_val1 + real_val2;
      fp_result = real_to_fp(real_result);
    end else if (t.funct7 == MUL) begin
      real_val1 = fp_to_real(t.fp1);
      real_val2 = fp_to_real(t.fp2);
      real_result = real_val1 * real_val2;
      fp_result = real_to_fp(real_result);
    end else if (t.funct7 == SUB) begin
      real_val1 = fp_to_real(t.fp1);
      real_val2 = fp_to_real(t.fp2);
      real_result = real_val1 - real_val2;
      fp_result = real_to_fp(real_result);
    end
    // assigning all the values to output transaction
    output_tx.fp1 = t.fp1;
    output_tx.fp2 = t.fp2;
    output_tx.frm = t.frm;
    output_tx.funct7 = t.funct7;
    output_tx.fp_out = fp_result;
    // output_tx.flags = 
    ap_pred.write(output_tx);
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

