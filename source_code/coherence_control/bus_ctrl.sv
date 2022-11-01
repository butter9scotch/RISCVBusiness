/*
*	Copyright 2022 Purdue University
*		
*	Licensed under the Apache License, Version 2.0 (the "License");
*	you may not use this file except in compliance with the License.
*	You may obtain a copy of the License at
*		
*	    http://www.apache.org/licenses/LICENSE-2.0
*		
*	Unless required by applicable law or agreed to in writing, software
*	distributed under the License is distributed on an "AS IS" BASIS,
*	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*	See the License for the specific language governing permissions and
*	limitations under the License.
*
*
*	Filename:     bus_ctrl.sv
*
*	Created by:   Jimmy Mingze Jin
*	Email:        jin357@purdue.edu
*	Date Created: 10/24/2022
*	Description:  Bus controller for MESI cache coherence; extended from coherence_ctrl.sv
*/

`include "coherence_ctrl_if.vh"

module bus_ctrl #( 
    parameter BLOCK_SIZE = 2,
    parameter CPUS = 2
)(  
    input logic CLK, nRST, 
    bus_ctrl_if.cc ccif
);  
    // localparams and variables
    // localparam COUNTER_LENGTH = $clog2(BLOCK_SIZE/2); // 64 bit memory bandwidth
    localparam CPU_ID_LENGTH = $clog2(CPUS);
    // logic [COUNTER_LENGTH-1:0] count, ncount;
    bus_state_t state, nstate; 
    logic [CPU_ID_LENGTH-1:0] requester_cpu, nrequester_cpu;
    logic [CPU_ID_LENGTH-1:0] supplier_cpu, nsupplier_cpu;
    word_t [CPUS-1:0] nccsnoopaddr;
    logic [CPUS-1:0] nccwait, nccinv;
    longWord_t ndload;
    
    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            requester_cpu <= '0;
            supplier_cpu <= '0;
            nosupplier <= 1;
            counter <= '0;
            state <= IDLE; 
            // cc outputs
            ccif.snoopaddr <= '0;
            ccif.ccinv <= '0;
            ccif.dload <= '0;
        end
        else begin
            requester_cpu <= nrequester_cpu;
            supplier_cpu <= nsupplier_cpu;
            nosupplier <= n_nosupplier;
            counter <= ncounter; 
            state <= nstate;
            // cc outputs
            ccif.snoopaddr <= nccsnoopaddr;
            ccif.ccinv <= nccinv;
            ccif.dload[requester_cpu] <= ndload;
        end
    end

    // next state logic for bus FSM
    always_comb begin 
        nstate = state;
        casez (state)
            IDLE:  begin
                if (|ccif.dWEN)                         nstate = WMEM;
                else if (|(ccif.dREN))                  nstate = SNOOP;
            end    
            SNOOP:          nstate = ccif.ccsnoophit[nsupplier_cpu] ? TRANSFER : RMEM;
            SNOOPX:         nstate = ccif.ccsnoophit[nsupplier_cpu] ? TRANSFERX : RMEMX;
            RMEM:           nstate = !ccif.dwait[requester_cpu] ? IDLE : state;  // will add counter
            RMEMX:          nstate = !ccif.dwait[requester_cpu] ? IDLE : state;
            TRANSFER_0:     nstate = TRANSFER_1;
            TRANSFER_1:     nstate = IDLE;
            TRANSFERX_0:    nstate = TRANSFERX_1;
            TRANSFERX_1:    nstate = TRANSFERX_2;
            TRANSFERX_2:    nstate = !ccif.dwait[supplier_cpu] ? IDLE : state;
            WMEM:           nstate = !ccif.dwait[requester_cpu] ? IDLE : state;
        endcase
    end

    // supplier CPU arbitration
    always_comb begin
        nsupplier_cpu = supplier_cpu;
        n_nosupplier = nosupplier;
        if (state == SNOOP || state == SNOOPX) begin
            n_nosupplier = 0;
            casez (ccif.ccsnoophit)
                4'b1zzz: nsupplier_cpu = 3;
                4'b01zz: nsupplier_cpu = 2;
                4'b001z: nsupplier_cpu = 1;
                4'b0001: nsupplier_cpu = 0;
                4'b0000: n_nosupplier = 1;
            endcasez
        end
    end

    // output logic for bus FSM
    always_comb begin
        // defaults
        nrequester_cpu = requester_cpu;
        ccif.dwait = '1; 
        ccif.ccwait = '0; 
        ccif.l2addr = '0; 
        ccif.l2store = '0; 
        ccif.l2REN = '0; 
        ccif.l2WEN = '0; 
        ccif.ccexclusive = '0;
        nccinv = '0;
        ndload = ccif.dload[requester_cpu];
        casez(state)
            // determine requester CPU
            IDLE: begin
                casez (cctrans) // assume 4 cores for now
                    4'b1zzz: nrequester_cpu = 3;
                    4'b01zz: nrequester_cpu = 2;
                    4'b001z: nrequester_cpu = 1;
                    4'b0001: nrequester_cpu = 0;
                endcasez
            end
            // attempt to snoop all other caches
            SNOOP: begin
                n_nosupplier = 0;
                ccif.ccwait = '1 & ~(1 << requester_cpu);
                for (int i = 0; i < CPUS; i++) begin
                    if (requester_cpu != i)
                        nccsnoopaddr = ccif.daddr[requester_cpu];
                end
            end
            // attempt to snoop all other caches; invalidate on the next clk
            SNOOPX: begin
                nccinv = '1 & ~(1 << requester_cpu);
                n_nosupplier = 0;
                ccif.ccwait = '1 & ~(1 << requester_cpu);
                for (int i = 0; i < CPUS; i++) begin
                    if (requester_cpu != i)
                        nccsnoopaddr = ccif.daddr[requester_cpu];
                end
            end
            // respond with reading L2 if no snoop hit; update to E if exclusive
            RMEM: begin
                ccif.l2REN = 1'b1; 
                ccif.l2addr = ccif.daddr[requester_cpu]; 
                ccif.dload[requester_cpu] = ccif.l2load; 
                ccif.dwait[requester_cpu] = !(ccif.l2state == L2_ACCESS); 
                ccif.ccexclusive[requester_cpu] = !(|ccif.ccexclusivehit); 
            end
            // respond with reading L2 if no snoopx hit; update to M
            RMEMX: begin
                ccif.l2REN = 1'b1; 
                ccif.l2addr = ccif.daddr[requester_cpu]; 
                ccif.dload[requester_cpu] = ccif.l2load; 
                ccif.dwait[requester_cpu] = !(ccif.l2state == L2_ACCESS); 
                ccif.ccexclusive[requester_cpu] = 1;
            end
            // respond with cache-to-cache on snoop/snoopx hit; first write to bus
            TRANSFER_0, TRANSFERX_0: begin
                ndload = ccif.dstore[supplier_cpu]; 
            end
            // respond with cache-to-cache on snoop/snoopx hit; second write to requester
            TRANSFER_1, TRANSFERX_1: begin
                ccif.dwait[requester_cpu] = 1'b0;
            end
            // final writeback for snoopx hit, invalidation done prior
            TRANSFERX_2: begin
                ccif.l2store = ccif.dstore[supplier_cpu]; 
                ccif.l2addr = ccif.daddr[supplier_cpu]; 
                ccif.l2WEN = 1'b1; 
                ccif.dwait[supplier_cpu] = !(ccif.l2state == L2_ACCESS); 
            end
            // evictions may occur
            WMEM: begin
                ccif.l2store = ccif.dstore[requester_cpu]; 
                ccif.l2addr = ccif.daddr[requester_cpu]; 
                ccif.l2WEN = 1'b1; 
                ccif.dwait[requester_cpu] = !(ccif.l2state == L2_ACCESS); 
            end
        endcase
    end
endmodule