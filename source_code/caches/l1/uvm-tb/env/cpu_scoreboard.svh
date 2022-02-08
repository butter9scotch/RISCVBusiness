import uvm_pkg::*;
`include "uvm_macros.svh"

class cpu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(cpu_scoreboard)
  uvm_analysis_export #(cpu_transaction) expected_export; // receive result from predictor
  uvm_analysis_export #(cpu_transaction) actual_export; // receive result from DUT
  uvm_tlm_analysis_fifo #(cpu_transaction) expected_fifo;
  uvm_tlm_analysis_fifo #(cpu_transaction) actual_fifo;

  int m_matches, m_mismatches; // records number of matches and mismatches

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
    cpu_transaction expected_tx; //transaction from predictor
    cpu_transaction actual_tx;  //transaction from DUT
    forever begin
      expected_fifo.get(expected_tx);
      actual_fifo.get(actual_tx);
      // uvm_report_info("Comparator", $psprintf("\nexpected:\nrollover_val: %d\nnum_clk: %d\ncount_out: %d\nflag: %d\n~~~~~~~~~~~~~~~~~~\nactual:\ncount_out: %d\nflag:%d\n", expected_tx.rollover_value, expected_tx.num_clk, expected_tx.result_count_out, expected_tx.result_flag, actual_tx.result_count_out, actual_tx.result_flag));
      
      if(expected_tx.compare(actual_tx)) begin
        m_matches++;
        uvm_report_info("CPU Scoreboard", "Data Match");
      end else begin
        m_mismatches++;
        //TODO: ADD AN INFO PRINT STATEMENT HERE FOR DEBUGGING
        uvm_report_error("CPU Scoreboard", "Error: Data Mismatch");
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_info("CPU Scoreboard", $sformatf("Matches:    %0d", m_matches));
    uvm_report_info("CPU Scoreboard", $sformatf("Mismatches: %0d", m_mismatches));
  endfunction

endclass : cpu_scoreboard
