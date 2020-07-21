import uvm_pkg::*;
`include "uvm_macros.svh"

`include "FPU_if.svh"

class FPU_comparator extends uvm_scoreboard;
  `uvm_component_utils(FPU_comparator)
  uvm_analysis_export #(FPU_transaction) expected_export; // receive result from predictor
  uvm_analysis_export #(FPU_transaction) actual_export; //receive result from DUT
  uvm_tlm_analysis_fifo #(FPU_transaction) expected_fifo;
  uvm_tlm_analysis_fifo #(FPU_transaction) actual_fifo;

  int m_matches, m_mismatches;
  function new( string name , uvm_component parent) ;
		super.new( name , parent );
	  	m_matches = 0;
	  	m_mismatches = 0;
 	endfunction

  function void build_phase( uvm_phase phase );
    expected_export = new("expected_export", this);
    actual_export = new("actual_export", this);
    expected_fifo = new("expected_fifo", this);
    actual_fifo = new("actual_fifo", this);
	endfunction

  function void connect_phase(uvm_phase phase);
    expected_export.connect(expected_fifo.analysis_export);
    actual_export.connect(actual_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    FPU_transaction expected_tx; //transaction from predictor
    FPU_transaction actual_tx;  //transction from DUT
    forever begin
      expected_fifo.get(expected_tx);
      actual_fifo.get(actual_tx);
      uvm_report_info("FPU Comparator", $psprintf("\nexpected:\nfp1 %h\nfp2 %h\nfunct7 %b\nfrm %b\nfp_out %h\nflag: %h\n~~~~~~~~~~~~~~~~~~\nactual:\nfp_out %h\nflag: %h\n", expected_tx.fp1, expected_tx.fp2, expected_tx.funct7, expected_tx.frm, expected_tx.fp_out, expected_tx.flags, actual_tx.fp_out, actual_tx.flags));
      if((actual_tx.fp_out == expected_tx.fp_out) || (actual_tx.fp_out == expected_tx.fp_out + 1)) begin
        m_matches++;
        uvm_report_info("FPU Comparator", "Data Match");
      end else begin
        m_mismatches++;
        uvm_report_error("FPU Comparator", "Error: Data Mismatch");
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_info("FPU Comparator", $sformatf("Matches:    %0d", m_matches));
    uvm_report_info("FPU Comparator", $sformatf("Mismatches: %0d", m_mismatches));
  endfunction

endclass
