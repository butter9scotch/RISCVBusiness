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
*	Filename:     bus_ctrl_if.vh
*
*	Created by:   Jimmy Mingze Jin
*	Email:        jin357@purdue.edu
*	Date Created: 10/31/2022
*	Description:  Bus controller connections
*/

`ifndef BUS_CTRL_IF_VH
`define BUS_CTRL_IF_VH

// parameters
parameter CPUS = 4;
parameter BLOCK_SIZE = 2;
localparam DATA_WIDTH = 32 * BLOCK_SIZE; // 64 bit/clk memory bandwidth

// coherence bus controller states
typedef enum logic [3:0] {  
    IDLE,               // determines if a request is going on
    SNOOP,              // sends a snoop request to all cores not the req
    SNOOP_INV,          // sends a snoop & invalidation request to all cores not the req
    RMEM,               // reads from l2 to bus
    RMEM_INV,           // reads from l2 to bus, only when promoting to modified
    RMEM_FIN,           // finishes transaction by providing from bus to cache
    RMEM_EXCL_FIN,      // finishes transaction as well as updates cache to exclusive
    TRANSFER,           // provides cache to bus transfer
    TRANSFER_INV,       // provides cache to bus transfer, only when promoting to modified
    TRANSFER_FIN,       // provides bus to requester transfer
    TRANSFER_INV_FIN,   // provides bus to requester transfer as well as updates cache to exclusive
    WMEM,               // initiates an eviction request by writing to the bus
    WMEM_TRANSFER,      // initiates a writeback due to cache to cache
    WMEM_FIN,           // attempts to write value into l2
    UPDATE,             // sends an invalidation request
    UPDATE_FIN          // completes an invalidation request
} bus_state_t;

/*
* dummy l2 states
* FREE -> IDLE
* BUSY -> IN TRANSITIONS
* ACCESS -> HIT
* ERROR -> yikes
*/
typedef enum logic [1:0] {
    L2_FREE, L2_BUSY, L2_ACCESS, L2_ERROR
} l2_state_t;

// taken from coherence_ctrl_if.vh
typedef logic [31:0] word_t;
typedef logic [DATA_WIDTH-1:0] longWord_t;

// modified from coherence_ctrl_if.vh
interface bus_ctrl_if;
    // L1 generic control signals
    logic       [CPUS-1:0] dREN, dWEN, dwait; 
    longWord_t  [CPUS-1:0] dload, dstore;
    word_t      [CPUS-1:0] daddr;
    // L1 coherence INPUTS to bus 
    logic       [CPUS-1:0] cctrans;     // indicates that the requester is undergoing a miss
    logic       [CPUS-1:0] ccwrite;     // indicates that the requester is attempting to go to M
    logic       [CPUS-1:0] ccsnoophit;  // indicates that the responder has the data
    logic       [CPUS-1:0] ccIsPresent; // indicates that nonrequesters have the data valid
    logic       [CPUS-1:0] ccdirty;     // indicates that we have [I -> S, M -> S]
    // L1 coherence OUTPUTS
    logic       [CPUS-1:0] ccwait;      // indicates a potential snoophit wait request
    logic       [CPUS-1:0] ccinv;       // indicates an invalidation request
    logic       [CPUS-1:0] ccexclusive; // indicates an exclusivity update
    word_t      [CPUS-1:0] ccsnoopaddr; 
    // L2 signals
    l2_state_t l2state; 
    longWord_t l2load, l2store; 
    logic l2WEN, l2REN; 
    word_t l2addr; 

    // modports
    modport cc(
        input   dREN, dWEN, daddr, dstore, 
                cctrans, ccwrite, ccsnoophit, ccIsPresent, ccdirty,
                l2load, l2state, 
        output  dwait, dload, 
                ccwait, ccinv, ccsnoopaddr, ccexclusive, 
                l2addr, l2store, l2REN, l2WEN
    ); 

    modport tb(
        input   dwait, dload, 
                ccwait, ccinv, ccsnoopaddr, ccexclusive, 
                l2addr, l2store, l2REN, l2WEN,
        output  dREN, dWEN, daddr, dstore, 
                cctrans, ccwrite, ccsnoophit, ccIsPresent, ccdirty,
                l2load, l2state
    ); 

endinterface
`endif // BUS_CTRL_IF_VH