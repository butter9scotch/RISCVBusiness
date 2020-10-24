import uvm_pkg::*;
`include "uvm_macros.svh"

`include "tb_FPU_transaction.svh"
`include "FPU_if.svh"

class FPU_comparator extends uvm_scoreboard;
  `uvm_component_utils(FPU_comparator)
  // uvm_analysis_export #(FPU_transaction) transaction_export; // receive result from predictor
  // uvm_tlm_analysis_fifo #(FPU_transaction) transaction_fifo;

  uvm_analysis_export #(FPU_response) actual_export; //receive result from DUT
  uvm_tlm_analysis_fifo #(FPU_response) actual_fifo;
  registerFile sim_rf;
  transactionSeq tx_seq;

  int m_matches, m_mismatches;
  function new( string name , uvm_component parent) ;
		super.new( name , parent );
	  	m_matches = 0;
	  	m_mismatches = 0;
 	endfunction

  function void build_phase( uvm_phase phase );
    // transaction_export = new("transaction_export", this);
    actual_export = new("actual_export", this);
    // transaction_fifo = new("transaction_fifo", this);
    actual_fifo = new("actual_fifo", this);
	endfunction

  function void connect_phase(uvm_phase phase);
    // transaction_export.connect(transaction_fifo.analysis_export);
    actual_export.connect(actual_fifo.analysis_export);
  endfunction

  task run_phase(uvm_phase phase);
    FPU_transaction err_tx;
    FPU_response resp;
    int index;
    // FPU_transaction tx;
    logic [31:0] expected_out;
    forever begin
      actual_fifo.get(resp);
      // transaction_fifo.get(tx);
      expected_out = sim_rf.read(resp.f_rs2);

      uvm_report_info("FPU Comparator", $psprintf("\n~~~~~~~~~~~~~~~~~~~~~~~~~~~\nsimulated register[%d]: %h\nactual register[%d]   : %h\n~~~~~~~~~~~~~~~~~~~~~~~~~~~", resp.f_rs2, expected_out, resp.f_rs2, resp.FPU_all_out));
      if((resp.FPU_all_out == expected_out) || (resp.FPU_all_out == expected_out + 1)) begin
        m_matches++;
        uvm_report_info("FPU Comparator", "Data Match");
      end else begin
        m_mismatches++;
        $info("Current time");
        uvm_report_error("FPU Comparator", "Error: Data Mismatch");
        //print out most recent transaction that goes wrong
        err_tx = tx_seq.search(resp.f_rs2);
        index = tx_seq.search_index(resp.f_rs2);
        uvm_report_info("FPU Comparator",  $psprintf("\nCurrent transaction index: %d\nTransaction that went wrong index: %d\n", tx_seq.index, index));
        err_tx.print();
      end
    end
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_info("FPU Comparator", $sformatf("Matches:    %0d", m_matches));
    uvm_report_info("FPU Comparator", $sformatf("Mismatches: %0d", m_mismatches));
  endfunction

endclass
