`include "generic_bus_if.vh"

module memory_arbiter (
    input CLK, nRST,
    generic_bus_if.generic_bus icache_if, dcache_if,
    generic_bus_if.cpu mem_arb_if
);
    typedef enum logic[1:0] {IDLE, IREQUEST, DREQUEST} state_t;
    state_t state, next_state;

	generic_bus_if next_icache_if_out();
	generic_bus_if next_dcache_if_out();

	generic_bus_if next_mem_if();

	always_ff @(posedge CLK, negedge nRST) begin : OUTPUT_LOGIC_FF
		if (!nRST) begin
			icache_if.rdata		<= '0;
			icache_if.busy 		<= '1;

			dcache_if.rdata		<= '0;
			dcache_if.busy 		<= '1;

			mem_arb_if.ren 	  	<= '0;
			mem_arb_if.wen 	  	<= '0;
			mem_arb_if.addr   	<= '0;
			mem_arb_if.wdata  	<= '0;
			mem_arb_if.byte_en	<= '0;
		end else begin
			icache_if.rdata		<= next_icache_if_out.rdata;
			icache_if.busy 		<= next_icache_if_out.busy;

			dcache_if.rdata		<= next_dcache_if_out.rdata;
			dcache_if.busy 		<= next_dcache_if_out.busy;

			mem_arb_if.ren 	  	<= next_mem_if.ren;
			mem_arb_if.wen 	  	<= next_mem_if.wen;
			mem_arb_if.addr   	<= next_mem_if.addr;
			mem_arb_if.wdata  	<= next_mem_if.wdata;
			mem_arb_if.byte_en	<= next_mem_if.byte_en;
		end
	end
    
    always_comb begin : NEXT_OUTPUT_LOGIC
		next_mem_if.ren 	  		= '0;
		next_mem_if.wen 	  		= '0;
		next_mem_if.addr   			= '0;
		next_mem_if.wdata  			= '0;
		next_mem_if.byte_en			= '0;

		next_icache_if_out.busy 	= '1;
		next_icache_if_out.rdata   	= '0;

		next_dcache_if_out.busy		= '1;
		next_dcache_if_out.rdata   	= '0;

		case(state)
			IDLE: begin
				if(dcache_if.wen || dcache_if.ren) begin
					next_mem_if.ren 	  		= dcache_if.ren;
					next_mem_if.wen 	  		= dcache_if.wen;
					next_mem_if.addr   			= dcache_if.addr;
					next_mem_if.wdata  			= dcache_if.wdata;
					next_mem_if.byte_en			= dcache_if.byte_en;
					next_dcache_if_out.busy 	= mem_arb_if.busy;
					next_dcache_if_out.rdata 	= mem_arb_if.rdata;
				end
				else if(icache_if.wen || icache_if.ren) begin
					next_mem_if.ren 	  		= icache_if.ren;
					next_mem_if.wen 	  		= icache_if.wen;
					next_mem_if.addr   			= icache_if.addr;
					next_mem_if.wdata  			= icache_if.wdata;
					next_mem_if.byte_en			= icache_if.byte_en;
					next_icache_if_out.busy 	= mem_arb_if.busy;
					next_icache_if_out.rdata 	= mem_arb_if.rdata;
				end 
			end
			IREQUEST: begin
				next_mem_if.ren 	  		= icache_if.ren;
				next_mem_if.wen 	  		= icache_if.wen;
				next_mem_if.addr   			= icache_if.addr;
				next_mem_if.wdata  			= icache_if.wdata;
				next_mem_if.byte_en			= icache_if.byte_en;
				next_icache_if_out.busy 	= mem_arb_if.busy;
				next_icache_if_out.rdata 	= mem_arb_if.rdata;
			end
			DREQUEST: begin
				next_mem_if.ren 	  		= dcache_if.ren;
				next_mem_if.wen 	  		= dcache_if.wen;
				next_mem_if.addr   			= dcache_if.addr;
				next_mem_if.wdata  			= dcache_if.wdata;
				next_mem_if.byte_en			= dcache_if.byte_en;
				next_dcache_if_out.busy 	= mem_arb_if.busy;
				next_dcache_if_out.rdata 	= mem_arb_if.rdata;
			end 
		endcase
	end

   	always_comb begin : NEXT_STATE_LOGIC
       	next_state  = state;

       	case(state)
			IDLE: begin
				if((dcache_if.wen || dcache_if.ren) && mem_arb_if.busy) begin
					next_state  = DREQUEST;
				end
				else if((icache_if.wen || icache_if.ren) && mem_arb_if.busy) begin
					next_state  = IREQUEST;
				end
			end
			DREQUEST: begin
				if(~next_mem_if.busy) begin // hopefully, busy will always be high until fetch, so no problem
					next_state  = IDLE;
				end
			end
			IREQUEST: begin
				if(~next_mem_if.busy) begin
					next_state  = IDLE;
				end
			end
      	endcase
   	end
    
   	always_ff @ (posedge CLK, negedge nRST) begin : STATE_FF
       	if(~nRST) begin
	   		state <= IDLE;
       	end 
		else begin
	   		state <= next_state;
       	end
   	end
    
endmodule
