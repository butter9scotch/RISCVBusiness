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
    parameter BLOCK_SIZE = 2,
    parameter CPUS = 4
)(  
    input logic CLK, nRST, 
    bus_ctrl_if.cc ccif
);  
    // localparams/imports
    localparam CPU_ID_LENGTH = $clog2(CPUS);
    // states
    bus_state_t state, nstate;
    // requester/supplier
    logic [CPU_ID_LENGTH-1:0] requester_cpu, nrequester_cpu;
    logic [CPU_ID_LENGTH-1:0] supplier_cpu, nsupplier_cpu;
    logic nosupplier, n_nosupplier;
    // support for flopped outputs
    word_t [CPUS-1:0] nccsnoopaddr, nl2_addr;
    logic [CPUS-1:0] nccwait, nccinv;
    transfer_width_t ndload, nl2_store;
    // internal store for if we want to update to exclusive
    logic exclusiveUpdate, nexclusiveUpdate;
    // MESI(F) forwarding
    // logic [CPUS-1:0] ccforward, nccforward;

    // FF
    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            // requester/supplier arbitration
            requester_cpu <= '0;
            supplier_cpu <= '0;
            nosupplier <= 1;
            // if we need to update the cache ot exclusive
            exclusiveUpdate <= 0;
            // state machine for bus controller
            state <= IDLE; 
            // cc latched addr
            ccif.ccsnoopaddr <= '0;
            // store/load/addr to l2 (broken up from l1)
            ccif.dload <= '0;
            ccif.l2store <= '0;
            ccif.l2addr <= '0;
            // ccforward <= 0;
        end
        else begin
            requester_cpu <= nrequester_cpu;
            supplier_cpu <= nsupplier_cpu;
            nosupplier <= n_nosupplier;
            state <= nstate;
            exclusiveUpdate <= nexclusiveUpdate;
            ccif.ccsnoopaddr <= nccsnoopaddr;
            ccif.dload[requester_cpu] <= ndload;
            ccif.l2store <= nl2_store;
            ccif.l2addr <= nl2_addr;
            // ccforward <= nccforward;
        end
    end

    // next state logic for bus FSM
    always_comb begin 
        nstate = state;
        casez (state)
            IDLE:  begin
                if (|ccif.dWEN)
                    nstate = EVICT;
                else if (|(ccif.dREN & ccif.ccwrite))                  
                    nstate = SNOOP_INV;
                else if (|(ccif.dREN))                  
                    nstate = SNOOP;
                else if (|ccif.ccwrite)
                    nstate = UPDATE;
            end
            SNOOP:              nstate = |ccif.ccsnoophit ? TRANSFER : RMEM;
            SNOOP_INV:          nstate = |ccif.ccsnoophit ? TRANSFER_INV : RMEM_INV;
            // SNOOP:              nstate = |nccforward ? TRANSFER : IDLE;
            // SNOOP_INV:          nstate = |nccforward ? TRANSFER_INV : IDLE;
            RMEM:               nstate = (ccif.l2state == L2_ACCESS) ? (exclusiveUpdate ? RMEM_EXCL_FIN : RMEM_FIN) : state;
            RMEM_INV:           nstate = (ccif.l2state == L2_ACCESS) ? RMEM_EXCL_FIN : state;
            RMEM_FIN:           nstate = IDLE;
            RMEM_EXCL_FIN:      nstate = IDLE;
            TRANSFER_INV:       nstate = TRANSFER_INV_FIN;
            TRANSFER_INV_FIN:   nstate = IDLE;
            TRANSFER:           nstate = TRANSFER_FIN;
            TRANSFER_FIN:       nstate = ccif.ccdirty[supplier_cpu] ? WMEM_TRANSFER : IDLE;
            WMEM_TRANSFER:      nstate = WMEM_TRANSFER_FIN;
            WMEM_TRANSFER_FIN:  nstate = (ccif.l2state == L2_ACCESS) ? IDLE : state;
            EVICT:              nstate = (ccif.l2state == L2_ACCESS) ? IDLE : state;
            UPDATE:             nstate = IDLE;
        endcase
    end

    // supplier and requester CPU arbitration
    always_comb begin
        nsupplier_cpu = supplier_cpu;
        n_nosupplier = nosupplier;
        nrequester_cpu = requester_cpu;
        if (state == SNOOP || state == SNOOP_INV) begin
            n_nosupplier = 1;
            // determine supplier from snoophits
            for (int i = 0; i < CPUS; i++) begin
                if (ccif.ccsnoophit[i]) begin
                    nsupplier_cpu = i;
                    n_nosupplier = 0;
                end
            end
            // for (int i = 0; i < CPUS; i++) begin
            //     if (ccif.ccIsPresent[i]) begin
            //         nsupplier_cpu = i;
            //         n_nosupplier = 0;
            //     end
            // end
        end
        if (state == IDLE) begin
            for (int i = 0; i < CPUS; i++) begin
                if (ccif.cctrans[i])
                    nrequester_cpu = i;
            end
        end
    end

    // output logic for bus FSM
    always_comb begin
        // defaults
        nccsnoopaddr = ccif.ccsnoopaddr;
        ccif.dwait = '1; 
        ccif.ccwait = '0; 
        nl2_addr = ccif.l2addr; 
        nl2_store = ccif.l2store; 
        ccif.l2REN = '0; 
        ccif.l2WEN = '0; 
        ccif.ccexclusive = '0;
        ccif.ccinv = '0;
        ndload = ccif.dload[requester_cpu];
        nexclusiveUpdate = exclusiveUpdate;
        // nccforward = ccforward;
        casez(state)
            // IDLE (maybe guard with if nstate != state to reduce the amount of 1 -> 0 -> 1 switches)
            IDLE: begin
                // beneficial when transitioning to snoop
                for (int i = 0; i < CPUS; i++) begin
                    if (requester_cpu != i)
                        nccsnoopaddr[i] = ccif.daddr[nrequester_cpu] & ~(word_t'(3'b111));
                end
                // beneficial when transitioning to WB
                nl2_store = ccif.dstore[nrequester_cpu]; 
                nl2_addr = ccif.daddr[nrequester_cpu] & ~(word_t'(3'b111));
                // forwarding if multipresent, we choose to forward from the msb
                // nccforward = 0;
                // for (int i = 0; i < CPUS; i++) begin
                //     if (ccif.ccIsPresent[i])
                //         nccforward = 1 << i;
                // end
            end
            // attempt to snoop all other caches
            SNOOP: begin
                nexclusiveUpdate = !(|ccif.ccIsPresent);
                ccif.ccwait = nonrequesterToggle(requester_cpu);
            end
            // attempt to snoop all other caches; invalidate on the next clk
            SNOOP_INV: begin
                nexclusiveUpdate = !(|ccif.ccIsPresent);
                ccif.ccinv = nonrequesterToggle(requester_cpu);
                ccif.ccwait = nonrequesterToggle(requester_cpu);
            end
            // respond with reading L2 if no snoop hit; update to E if exclusive
            RMEM, RMEM_INV: begin
                ccif.l2REN = 1; 
                nl2_addr = ccif.daddr[requester_cpu] & ~(word_t'(3'b111));
                ndload[requester_cpu] = ccif.l2load; 
            end
            RMEM_FIN: begin
                ccif.dwait[requester_cpu] = 0;
            end
            RMEM_EXCL_FIN: begin
                ccif.ccexclusive[requester_cpu] = 1;
                ccif.dwait[requester_cpu] = 0;
            end
            // respond with cache-to-cache on snoop/snoopx hit; first, write to bus
            TRANSFER, TRANSFER_INV: begin
                ndload = ccif.dstore[supplier_cpu];
                ccif.ccwait = nonrequesterToggle(requester_cpu);
            end
            // respond with cache-to-cache on snoop/snoopx hit; second, write to requester
            TRANSFER_FIN: begin
                ccif.dwait[requester_cpu] = 0;
                ccif.ccexclusive[requester_cpu] = 0;    // [I -> E, M -> I] is not possible
            end
            TRANSFER_INV_FIN: begin
                ccif.dwait[requester_cpu] = 0;
                ccif.ccexclusive[requester_cpu] = 1;    // [I -> E, M -> I] is not possible
            end
            // final writeback for snoop hit; [I -> S; M -> S needs a WB as S can be replaced]
            WMEM_TRANSFER: begin
                // doing writebacks strictly after transfers for now, hoping that I -> S; M -> S is not too frequent (else warrants O state)
                nl2_store = ccif.dstore[supplier_cpu]; 
                nl2_addr = ccif.daddr[supplier_cpu] & ~(word_t'(3'b111));
                ccif.dwait[supplier_cpu] = 0; 
            end
            // evictions may occur (dWEN goes high)
            EVICT: begin
                ccif.dwait[requester_cpu] = 0;  // seems it cant be earlier unless i use nstate
                ccif.l2WEN = 1;
            end
            WMEM_TRANSFER_FIN: begin
                ccif.l2WEN = 1; 
            end
            // S -> M should invalidate the other caches, no need to WB as we have the latest data somewhere
            UPDATE: begin
                ccif.ccinv = nonrequesterToggle(requester_cpu);
                ccif.ccwait = nonrequesterToggle(requester_cpu);
                ccif.ccexclusive[requester_cpu] = 1;
            end
        endcase
    end

    // function to obtain all non requesters (because it looks cryptic)
    function logic [CPUS-1:0] nonrequesterToggle;
        input requester_cpu;
        nonrequesterToggle = '1 & ~(1 << requester_cpu);
    endfunction
endmodule