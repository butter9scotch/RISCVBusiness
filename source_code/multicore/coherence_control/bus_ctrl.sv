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

`include "bus_ctrl_if.vh"

module bus_ctrl #( 
    parameter DOUBLE_BLOCK_SIZE = 1,    // BLOCK_SIZE == 2
    parameter CPUS = 4
)(  
    input logic CLK, nRST, 
    bus_ctrl_if.cc ccif
);  
    // localparams/imports
    localparam COUNT_LENGTH = $clog2(DOUBLE_BLOCK_SIZE); // 64 bit memory bandwidth
    localparam CPU_ID_LENGTH = $clog2(CPUS);
    // states
    bus_state_t state, nstate;
    // requester/supplier
    logic [CPU_ID_LENGTH-1:0] requester_cpu, nrequester_cpu;
    logic [CPU_ID_LENGTH-1:0] supplier_cpu, nsupplier_cpu;
    logic nosupplier, n_nosupplier;
    // support for flopped outputs
    word_t [CPUS-1:0] nccsnoopaddr;
    logic [CPUS-1:0] nccwait, nccinv;
    longWord_t ndload;
    // counter to ensure all bandwidth size is acted on
    logic [COUNT_LENGTH:0] count, ncount;
    logic count_complete;
    logic exclusiveUpdate, nexclusiveUpdate;

    // FF
    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            requester_cpu <= '0;
            supplier_cpu <= '0;
            nosupplier <= 1;
            exclusiveUpdate <= 0;
            state <= IDLE; 
            // cc outputs
            ccif.ccsnoopaddr <= '0;
            ccif.ccinv <= '0;
            ccif.dload <= '0;
            // count for number of 64 bit operations needed
            count <= '0;
        end
        else begin
            requester_cpu <= nrequester_cpu;
            supplier_cpu <= nsupplier_cpu;
            nosupplier <= n_nosupplier;
            count <= ncount; 
            state <= nstate;
            exclusiveUpdate <= nexclusiveUpdate;
            // cc outputs
            ccif.ccsnoopaddr <= nccsnoopaddr;
            ccif.ccinv <= nccinv;
            ccif.dload[requester_cpu] <= ndload;
            // count for number of 64 bit operations needed
            count <= ncount;

        end
    end

    // next state logic for bus FSM
    always_comb begin 
        nstate = state;
        casez (state)
            IDLE:  begin
                if (|ccif.dWEN)
                    nstate = WMEM;
                else if (|(ccif.dREN))                  
                    nstate = SNOOP;
                else if (|(ccif.dREN & ccif.ccwrite))                  
                    nstate = SNOOP_INV;
                else if (|ccif.cctrans)
                    nstate = UPDATE;
            end    
            SNOOP:          nstate = ccif.ccsnoophit[nsupplier_cpu] ? TRANSFER_0 : RMEM;                // snoop hits happen on both E/M
            SNOOP_INV:      nstate = ccif.ccsnoophit[nsupplier_cpu] ? TRANSFER_INV_0 : RMEM_INV;
            RMEM:           nstate = (count_complete && !ccif.dwait[requester_cpu]) ? IDLE : state;
            RMEM_INV:       nstate = (count_complete && !ccif.dwait[requester_cpu]) ? IDLE : state;
            TRANSFER_INV_0: nstate = TRANSFER_INV_1;
            TRANSFER_INV_1: nstate = IDLE;                                                              // must be a I -> M, M -> I transition
            TRANSFER_0:     nstate = TRANSFER_1;
            TRANSFER_1:     nstate = ccif.ccIsExclusive[supplier_cpu] ? IDLE : WMEM_TRANSFER;           // requester I -> S, supply on both E and M, but only WB if its in M
            WMEM_TRANSFER:  nstate = (count_complete && !ccif.dwait[supplier_cpu]) ? IDLE : state;
            WMEM:           nstate = (count_complete && !ccif.dwait[requester_cpu]) ? IDLE : state;
            UPDATE:         nstate = IDLE;
        endcase
    end

    // supplier CPU arbitration
    always_comb begin
        nsupplier_cpu = supplier_cpu;
        n_nosupplier = nosupplier;
        if (state == SNOOP || state == SNOOP_INV) begin
            n_nosupplier = 0;
            casez (ccif.ccsnoophit)
                4'b1zzz: nsupplier_cpu = 3;
                4'b01zz: nsupplier_cpu = 2;
                4'b001z: nsupplier_cpu = 1;
                4'b0001: nsupplier_cpu = 0;
                4'b0000: n_nosupplier = 1;
            endcase
        end
    end

    // counter, for current word
    always_comb begin
        ncount = count;
        count_complete = (count == (DOUBLE_BLOCK_SIZE - 1));
        // CLEAR when entering cache-cache or rmem
        if ((state == SNOOP || state == SNOOP_INV || state == UPDATE) && nstate != state)
            ncount = 0;
        // CLEAR when entering WMEM
        else if ((nstate == WMEM || nstate == WMEM_TRANSFER) && nstate != state)
            ncount = 0;
        // increment due to dwait = 0 from anything 
        // (dwait only matters for either req or sup; maybe can be simplified)
        else if (|(~ccif.dwait))
            ncount = count + 1;
    end

    // output logic for bus FSM
    always_comb begin
        // defaults
        nrequester_cpu = requester_cpu;
        nccsnoopaddr = ccif.ccsnoopaddr;
        ccif.dwait = '1; 
        ccif.ccwait = '0; 
        ccif.l2addr = '0; 
        ccif.l2store = '0; 
        ccif.l2REN = '0; 
        ccif.l2WEN = '0; 
        ccif.ccexclusive = '0;
        nccinv = '0;
        ndload = ccif.dload[requester_cpu];
        nexclusiveUpdate = exclusiveUpdate;
        casez(state)
            // determine requester CPU
            IDLE: begin
                nexclusiveUpdate = !(|ccif.ccIsExclusive); 
                casez (ccif.cctrans) // assume 4 cores for now
                    4'b1zzz: nrequester_cpu = 3;
                    4'b01zz: nrequester_cpu = 2;
                    4'b001z: nrequester_cpu = 1;
                    4'b0001: nrequester_cpu = 0;
                endcase
            end
            // attempt to snoop all other caches
            SNOOP: begin
                ccif.ccwait = '1 & ~(1 << requester_cpu);
                for (int i = 0; i < CPUS; i++) begin
                    if (requester_cpu != i)
                        nccsnoopaddr = ccif.daddr[requester_cpu] & ~(word_t'(3'b111));
                end
            end
            // attempt to snoop all other caches; invalidate on the next clk
            SNOOP_INV: begin
                nccinv = '1 & ~(1 << requester_cpu);
                ccif.ccwait = '1 & ~(1 << requester_cpu);
                for (int i = 0; i < CPUS; i++) begin
                    if (requester_cpu != i)
                        nccsnoopaddr = ccif.daddr[requester_cpu] & ~(word_t'(3'b111));
                end
            end
            // respond with reading L2 if no snoop hit; update to E if exclusive
            RMEM, RMEM_INV: begin
                ccif.l2REN = 1; 
                ccif.l2addr = ccif.daddr[requester_cpu] & ~(word_t'(3'b111));
                ccif.dload[requester_cpu] = ccif.l2load; 
                ccif.dwait[requester_cpu] = !(ccif.l2state == L2_ACCESS);
                ccif.ccexclusive[requester_cpu] = exclusiveUpdate;
            end
            // respond with cache-to-cache on snoop/snoopx hit; first, write to bus
            TRANSFER_0, TRANSFER_INV_0: begin
                ndload = ccif.dstore[supplier_cpu]; 
            end
            // respond with cache-to-cache on snoop/snoopx hit; second, write to requester
            TRANSFER_1, TRANSFER_INV_1: begin
                ccif.dwait[requester_cpu] = 0;
                ccif.ccexclusive[requester_cpu] = exclusiveUpdate;
            end
            // final writeback for snoop hit; [I -> S; M -> S needs a WB as S can be replaced]
            WMEM_TRANSFER: begin
                ccif.l2store = ccif.dstore[supplier_cpu]; 
                ccif.l2addr = ccif.daddr[supplier_cpu] & ~(word_t'(3'b111));
                ccif.l2WEN = 1; 
                ccif.dwait[supplier_cpu] = !(ccif.l2state == L2_ACCESS); 
            end
            // evictions may occur (dWEN goes high)
            WMEM: begin
                ccif.l2store = ccif.dstore[requester_cpu]; 
                ccif.l2addr = ccif.daddr[requester_cpu] & ~(word_t'(3'b111));
                ccif.l2WEN = 1; 
                ccif.dwait[requester_cpu] = !(ccif.l2state == L2_ACCESS); 
            end
            // S -> M should invalidate the other caches, no need to WB as we have the latest data somewhere
            UPDATE: begin
                nccinv = '1 & ~(1 << requester_cpu);
                ccif.ccwait = '1 & ~(1 << requester_cpu);
                for (int i = 0; i < CPUS; i++) begin
                    if (requester_cpu != i)
                        nccsnoopaddr = ccif.daddr[requester_cpu] & ~(word_t'(3'b111));
                end
            end
        endcase
    end
endmodule