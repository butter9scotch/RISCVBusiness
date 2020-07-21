import uvm_pkg::*;
`include "uvm_macros.svh"

`include "FPU_if.svh"

class FPU_comparator extends uvm_scoreboard;
  `uvm_component_utils(FPU_comparator)
  uvm_analysis_export #(FPU_response) actual_export; //receive result from DUT
  uvm_tlm_analysis_fifo #(FPU_transaction) actual_fifo;
  registerFile sim_rf;

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
    FPU_response resp;
    logic [31:0] expected_out;
    forever begin
      actual_fifo.get(resp);
      expected_out = sim_rf.read(resp.f_rs2);

      uvm_report_info("FPU Comparator", $psprintf("\n%d simulated register: %h\nactual register: %h\n", resp.f_rs2, expected_out, resp.FPU_all_out));
      if((resp.FPU_all_out == expected_out) || (resp.FPU_all_out == expected_out + 1)) begin
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
