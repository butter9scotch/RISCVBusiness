`ifndef AHB_BUS_MONITOR_SVH
`define AHB_BUS_MONITOR_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "bus_ctrl_if.vh"
class bus_monitor extends uvm_monitor;
  `uvm_component_utils(ahb_bus_monitor)

  localparam TRANS_SIZE = dut_params::WORD_W * dut_params::BLOCK_SIZE_WORDS;

  virtual bus_ctrl_if vif;

  uvm_analysis_port #(bus_transaction) bus_ap;
  uvm_analysis_port #(bus_transaction) result_ap;
  int timeoutCount;

  function new(string name, uvm_component parent = null);
    super.new(name, parent);
    bus_ap = new("bus_ap", this);
    result_ap  = new("result_ap", this);
  endfunction : new

  // Build Phase - Get handle to virtual if from config_db
  virtual function void build_phase(uvm_phase phase);
    if (!uvm_config_db#(virtual bus_ctrl_if)::get(this, "", "bus_ctrl_vif", vif)) begin
      `uvm_fatal("monitor", "No virtual interface specified for this monitor instance")
    end
  endfunction

// txi is the index inside of the tx arrays we are checking with
// vifi is the index in the virtual interface arrays we are checking with
// This function compares the tx and the virtual interface to dertermine if the 
//      transaction we have saved (at the txi index) matches the transaction on the interface (at vifi)
//      returns 1 if they are different, 0 otherwise
virtual function bit proc_req_different(bus_transaction tx, int txi, int vifi);
   if(!tx.procReq[vifi][txi]) begin
     return 1;
   end else if(tx.dWEN[vifi][txi] != vif.dWEN[vifii] || tx.dRENfi][txi] != !vif.dWEN[vifi]
                || tx.readX[vifi][txi] != vif.ccwrite[vifi] || tx.daddr[vifi][txi] != vif.daddr[vifi]
                || tx.dstore[vifi][txi] != vif.dstore[vifi]) begin
     return 1;
   end

   return 0;
end

endfunction


virtual function bus_transaction zeroTrans(bus_transaction tx);
  tx.idle = '0;
  tx.daddr = '0;
  tx.dWEN = '0;
  tx.readX = '0;
  tx.dstore = '0;
  tx.dload = '0;
  tx.exclusive = '0;
  tx.snoopHitAddr = '0;
  tx.snoopDirty = '0;
  tx.numTransactions = 0;

  tx.procReq = '0;
  tx.snoopReq = '0;
  tx.snoopRsp = '0;
  tx.busCtrlRsp = '0;
  tx.l2Req = '0;
  tx.l2Rsp = '0;
  tx.l2_rw = '0;
  tx.procReqAddr = '0;
  tx.l2ReqAddr = '0;
  tx.snoopReqAddr = '0;
  tx.snoopReqInvalidate = '0;
  tx.snoopRspType = '0;
  tx.procReqData = '0;
  tx.snoopRspData = '0;
  tx.l2RspData = '0;
  tx.l2StoreData = '0;
  tx.busCtrlRspData = '0;

  return tx;
endfunction
  /* 1) check for processor requests and place the request in the next available slot for the given cpu
     2) check for snoop requests, make sure that the snoop request to each cache is the same and place the general request into correct slot 
        based on addr (which CPU slot basically)
     3) check for snoop responses, make sure that if one says M then no others say M, if one says E then no others say E and depending on the
        response place the response into the correct slot based on addr (which CPU's slot basically)
     4) check for L2 requests by the bus_Ctrl and place into l2req location
     5) Check for l2 responses and place into l2 resp location
     6) Check for bus_ctrl rsp and place into the correct slot depending on the addresss. 
     NOTE: If we can't find a matching address at a given point for a given phase then it's a fatal error
     */
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      bus_transaction tx;
      timeoutCount = 0;
      bit transComplete = 0;
      bit snoopReqPhaseDone = 0;
      bit snoopRspPhaseDone = 0;
      bit l2ReqPhaseDone = 0;
      bit l2RspPhaseDone = 0;
      int cpuIndx[dut_params::NUM_CPUS_USED-1:0];
      int nonSnoopProc = 0; // this is the processor that should be recieving the data at the end!

      // Since not all of the snoops come at once we need to keep
      // stored versions of everyone's response until we get all of them
      bit [dut_params::NUM_CPUS_USED-1:0] snoopRsp;
      bit [dut_params::NUM_CPUS_USED-1:0] [1:0] snoopRspType;
      bit [dut_params::NUM_CPUS_USED-1:0] [TRANS_SIZE-1:0] snoopRspData;

      // captures activity between the driver and DUT
      tx = bus_transaction::type_id::create("tx");

      // zero out everything
      tx = zeroTrans(tx);

      `zero_unpckd_array(cpuIndx);
      
      while(!transComplete) begin
        @(posedge vif.clk);
        
        // Check for new processor requests
        // Throw error if we have write & read or write & ccwrite OR if a new request starts before the old one ends
        if(|vif.dREN || |vif.dWEN) begin
           for(int i = 0; i < dut_params::NUM_CPUS_USED; i++) begin
             if((vif.dREN[i] && vif.dWEN[i]) || (vif.dWEN[i] && vif.ccwrite[i])) begin
                `uvm_fatal("Monitor", $sformatf("Invalid combination of CPUS requests %d", i));
             end else if(vif.dREN[i] && proc_req_different(tx, cpuIndx[i], i)) begin
                if(tx.procReq[cpuIndx[i]]) begin
                  `uvm_fatal("Monitor", $sformatf("req not complete before new request! proc %d", i));
                end

                tx.procReq[i][cpuIndx[i]] = 1;
                tx.daddr[i][cpuIndx[i]] = vif.daddr[i];
                tx.dWEN[i][cpuIndx[i]]  = 0;
                tx.readX[i][cpuIndx[i]]  = vif.ccwrite;
             end else if(vif.dWEN[i] && proc_req_different(tx, cpuIndx[i], i)) begin
                if(tx.procReq[cpuIndx[i]]) begin
                  `uvm_fatal("Monitor", $sformatf("req not complete before new request! proc %d", i));
                end

                tx.procReq[i][cpuIndex[i]] = 1;
                tx.dWEN[i][cpuIndx[i]] = 1;
                tx.readX[i][cpuIndx[i]] = 0;
                tx.daddr[i][cpuIndx[i]] = vif.daddr[i];
            end
           end
        end

        // Check for new snoop requests
        if(|vif.ccwait && !snoopReqPhaseDone) begin
           for(int i = 0; i < dut_params::NUM_CPUS_USED; i++) begin
             // Figure out if this is the processor that's going to eventually recieve the data
             // If we have multiple being not snooped then this is a problem!!
             if(!vif.ccwait[i] && (nonSnoopProc == -1) && !snoopReqPhaseDone) begin
               nonSnoopProc = i;
             end else if(!vif.ccwait[i] && (nonSnoopProc != -1) && !snoopReqPhaseDone) begin
               `uvm_fatal("Monitor", $sformatf("Multiple processors not being snooped when one is!"));
             end
           end

           // make sure that if there's an invalidate signal that all of them are set except for the req being handled
           if(|vif.ccinv && !(&(vif.ccinv || (1'b1 << nonSnoopProc)))) begin
             `uvm_fatal("Monitor", "All snoops not recieving same invalidate signal!");
           end

           // Make sure that the snoop address is the same for all of them
           for(int i = 0; i < dut_params::NUM_CPUS_USED; i++) begin
             if((i != nonSnoopProc) && (vif.ccsnoopaddr[i] != tx.daddr[nonSnoopProc])) begin
                `uvm_fatal("Monitor", $sformatf("The snoop address does not match the processor request address, snooping into cpu #%d", i));
             end
           end

           // Now set the signals now that we've checked all of the conditions
           tx.snoopReq[nonSnoopProc][cpuIndx[nonSnoopProc]]  = 1;
           tx.snoopReqAddr[nonSnoopProc][cpuIndx[nonSnoopProc]]  = tx.daddr[nonSnoopProc];
           tx.snoopReqInvalidate[nonSnoopProc][cpuIndx[nonSnoopProc]]  = |vif.ccinv;
           snoopReqPhaseDone = 1;
           end
        end

       // Check for new snoop responses 
       // TODO: is snoop hit E a thing!!!??
       if((&((1'b1 << nonSnoopProc) | vif.snoopdone)) && !snoopRspPhaseDone) begin // if all of the processors are done being snooped into
         if(((1'b1 << nonSnoopProc) & vif.snoopDone) != 0) begin // this means the requester is responding, bad!
           `uvm_fatal("Monitor", "The requester is responding to the snoop!");
         end
         if(|vif.ccnoophit || |vif.ccIsPresent) begin // if we have a snoop hit
           if(|vif.ccdirty && ~(vif.ccdirty & (vif.ccdirty - 1))) begin // check that ccdirty is high and only 1 is set
             for(int i = 0; i < dut_params::NUM_CPUS_USED; i++) begin
               if(vif.ccdirty[i]) begin
                 tx.snoopRsp[nonSnoopProc][cpuIndx[nonSnoopProc]]  = 1;
                 tx.snoopRspType[nonSnoopProc][cpuIndx[nonSnoopProc]]  = 3; // snoop hit dirty
                 tx.snoopRspData[nonSnoopProc][cpuIndx[nonSnoopProc]]  = vif.dstore[i];
                 break;
               end
             end
           end else if(|vif.ccdirty) begin // this will happen if multiple say snoop hit dirty
             `uvm_fatal("Monitor", "Multiple snoop responses say dirty!");
           end else begin // we have snoop hit but none say dirty
             tx.snoopRsp[nonSnoopProc][cpuIndx[nonSnoopProc]]  = 1;

             // since we are in S or E then there are no L2 requests that need to be made
             l2RspPhaseDone = 1;
             l2ReqPhaseDone = 1;

             if((vif.ccsnoophit & (vif.ccsnoophit - 1)) == 0) begin // we only have a single hit which means this is an exclusive hit
               tx.snoopRspType[nonSnoopProc][cpuIndx[nonSnoopProc]]  = 2; // snoop hit E
             end else begin
               tx.snoopRspType[nonSnoopProc][cpuIndx[nonSnoopProc]]  = 1; // snoop hit S
               tx.snoopRspData[nonSnoopProc][cpuIndx[nonSnoopProc]]  = vif.dstore[(nonSnoopProc + 1) % dut_params::NUM_CPUS_USED]; // grab any of the data for now

               for(int i = 0; i < dut_params::NUM_CPUS_USED; i++) begin // check to make sure that everyone agrees on the data
                 if(i != nonSnoopProc && vif.dstore[i] != tx.snoopRspData[nonSnoopProc][cpuIndx[nonSnoopProc]] ) begin
                   `uvm_fatal("Monitor", "Snoop response (not dirty) don't all agree on the data!");
                 end
               end
             end
           end
         end else begin // if we don't have a snoop hit but the snoop is done with all processors
           tx.snoopRsp[nonSnoopProc][cpuIndx[nonSnoopProc]]  = 1;
           tx.snoopRspType[nonSnoopProc][cpuIndx[nonSnoopProc]]  = 0; // snoop done, no hit type
         end
         snoopRspPhaseDone = 1;
         timeoutCount = 0;
       end else if(snoopReqPhaseDone && !snoopRspPhaseDone) begin // if we have yet to do the snoop response and we have seen a snoop request
         timeoutCount = timeoutCount + 1;

         if(timeoutCount == 100) begin
           `uvm_fatal("Monitor", "Timeout of 100 cycles while waiting for all of the snoop responses");
         end
       end

       // Make sure that no L2 requests happen when they shouldn't
       if((vif.l2WEN || vif.l2REN) && ((tx.snoopRspType[nonSnoopProc][cpuIndx[nonSnoopProc]] == 1) || (tx.snoopRspType[nonSnoopProc][cpuIndx[nonSnoopProc]]  == 2))) begin
         `uvm_fatal("Monitor", "L2 request when snoop responses were S or E");
       end

       // Now check up on the L2 request
       if((vif.l2WEN || vif.l2REN) && snoopRspPhaseDone && !l2ReqPhaseDone) begin
         if(vif.l2WEN && vif.l2REN) begin
           `uvm_fatal("Monitor", "L2 read and write request at the same time!");
         end
         tx.l2Req[nonSnoopProc][cpuIndx[nonSnoopProc]] = 1; 
         tx.l2_rw[nonSnoopProc][cpuIndx[nonSnoopProc]] = vif.l2WEN;
         tx.l2ReqAddr[nonSnoopProc][cpuIndx[nonSnoopProc]] = vif.l2addr;
         tx.l2StoreData[nonSnoopProc][cpuIndx[nonSnoopProc]] = vif.l2store;
         l2ReqPhaseDone = 1;
       end else if(snoopRspPhaseDone && !l2ReqPhaseDone) begin // if we expect a l2 request
         timeoutCount = timeoutCount + 1;

         if(timeoutCount == 100) begin
           `uvm_fatal("Monitor", "Timeout of 100 cycles while waiting for l2 request to happen after snooping");
         end
       end

       // Now check up on the L2 response





        // Remember to set the nonSnoop processor to zero at the end
        // Also remember to update the cpuIndx(s) once the rsp is recieved from the bus controller!
        // Also remember to set the done flags to zero after the procRsp phase is complete

      end


    bus_ap.write(tx);

    // now write the result to the scoreboard!
    `uvm_info(this.get_name(), "New result sent to scoreboard", UVM_LOW);
    result_ap.write(tx);

    end
  endtask : run_phase

endclass : bus_monitor

`endif
