`include "generic_bus_if.vh"

module memory_arbiter (
    input CLK, nRST,
    generic_bus_if.generic_bus icache_if, dcache_if,
    generic_bus_if.cpu mem_arb_if
);
    typedef enum {IDLE, IREQUEST, DREQUEST} state_t;
    state_t state, next_state;
    
    // Output logic
    always_comb begin
	icache_if.busy 	  = 1'b1;
	dcache_if.busy 	  = 1'b1;
	icache_if.rdata   = '0;
	dcache_if.rdata   = '0;
	mem_arb_if.ren 	  = 1'b0;
	mem_arb_if.wen 	  = 1'b0;
	mem_arb_if.addr   = '0;
	mem_arb_if.wdata  = '0;

	casez(state)
	    IDLE: begin
		if(dcache_if.wen) begin
		    mem_arb_if.wen    = 1'b1;
		    mem_arb_if.addr   = dcache_if.addr;
		    mem_arb_if.wdata  = dcache_if.wdata;
		end // if (dcache_if.wen)
		else if(dcache_if.ren) begin
		    mem_arb_if.ren   = 1'b1;
		    mem_arb_if.addr  = dcache_if.addr;
		end
		else if(icache_if.ren) begin
		    mem_arb_if.ren   = 1'b1;
		    mem_arb_if.addr  = icache_if.addr;
		end
		else if(icache_if.wen) begin
		    mem_arb_if.wen    = 1'b1;
		    mem_arb_if.addr   = icache_if.addr;
		    mem_arb_if.wdata  = icache_if.wdata;
		end // if (icache_if.wen)
	    end // case: IDLE
	    IREQUEST: begin
		if(~mem_arb_if.busy && icache_if.wen) begin
		    icache_if.busy  = 1'b0;
		end
		else if(~mem_arb_if.busy) begin
		    icache_if.busy   = 1'b0;
		    icache_if.rdata  = mem_arb_if.rdata;
		end

		if(icache_if.wen) begin
		    mem_arb_if.wen    = 1'b1;
		    mem_arb_if.wdata  = icache_if.wdata;
		end
		else begin
		    mem_arb_if.ren  = 1'b1;
		end // else: !if(icache_if.wen)

		mem_arb_if.addr = icache_if.addr;
	    end // case: IREQUEST
	    DREQUEST: begin
		if(~mem_arb_if.busy && dcache_if.wen) begin
		    dcache_if.busy  = 1'b0;
		end
		else if(~mem_arb_if.busy) begin
		    dcache_if.busy   = 1'b0;
		    dcache_if.rdata  = mem_arb_if.rdata;
		end

		if(dcache_if.wen) begin
		    mem_arb_if.wen    = 1'b1;
		    mem_arb_if.wdata  = dcache_if.wdata;
		end
		else begin
		    mem_arb_if.ren  = 1'b1;
		end // else: !if(dcache_if.wen)

		mem_arb_if.addr  = dcache_if.addr;
	    end // case: DREQUEST
	endcase // casez (state)
    end // always_comb

   // next state logic
   always_comb begin
       next_state  = state;

       casez(state)
	   IDLE: begin
	       if(dcache_if.wen || dcache_if.ren) begin
		   next_state  = DREQUEST;
	       end
	       else if(icache_if.wen || icache_if.ren) begin
		   next_state  = IREQUEST;
	       end
	   end // case: IDLE
	   DREQUEST: begin
	       if(~mem_arb_if.busy) begin // hopefully, busy will always be high until fetch, so no problem
		   next_state  = IDLE;
	       end
	   end // case: DREQUEST
	   IREQUEST: begin
	       if(~mem_arb_if.busy) begin
		   next_state  = IDLE;
	       end
	   end // case: IREQUEST
       endcase // casez (state)
   end // always_comb
    
   always_ff @ (posedge CLK, negedge nRST) begin
       if(~nRST) begin
	   state <= IDLE;
       end
       else begin
	   state <= next_state;
       end // else: !if(~nRST)
   end // always_ff @
    
endmodule // memory_arbiter

