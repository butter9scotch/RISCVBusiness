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
*	Date Created: 11/01/2022
*	Description:  Bus controller connections
*/

`ifndef BUS_CTRL_IF_VH
`define BUS_CTRL_IF_VH

// coherence bus controller states
typedef enum logic {  
    IDLE, 
    SNOOP, SNOOPX,
    RMEM, RMEMX, 
    TRANSFER_0, TRANSFER_1, 
    TRANSFERX_0, TRANSFERX_1, TRANSFERX_2,
    WMEM
} bus_state_t;

// taken from coherence_ctrl_if.vh
typedef enum logic[1:0] {
    L2_FREE, L2_BUSY, L2_ACCESS, L2_ERROR
} l2_state_t;

// taken from coherence_ctrl_if.vh
typedef logic [31:0] word_t;
typedef logic [63:0] longWord_t;
parameter CPUS = 2;

// modified from coherence_ctrl_if.vh
interface bus_ctrl_if;
    // L1 generic control signals
    logic       [CPUS-1:0] dREN, dWEN, dwait; 
    longWord_t  [CPUS-1:0] daddr, dload, dstore; 
    // L1 coherence signals 
    logic       [CPUS-1:0] cctrans, ccwrite, ccsnoophit, ccexclusivehit;  
    logic       [CPUS-1:0] ccwait, ccinv, ccexclusive; 
    word_t      [CPUS-1:0] ccsnoopaddr; 
    // L2 signals
    l2_state_t l2state; 
    longWord_t l2load, l2store; 
    logic l2WEN, l2REN; 
    word_t l2addr; 

    // modports
    modport cc(
        input   dREN, dWEN, daddr, dstore, 
                cctrans, ccwrite, ccsnoophit, ccexclusivehit,
                l2load, l2state, 
        output  dwait, dload, 
                ccwait, ccinv, ccsnoopaddr, ccexclusive, 
                l2addr, l2store, l2REN, l2WEN
    ); 

    modport cc(
        input   dwait, dload, 
                ccwait, ccinv, ccsnoopaddr, ccexclusivehit, 
                l2addr, l2store, l2REN, l2WEN,
        output  dREN, dWEN, daddr, dstore, 
                cctrans, ccwrite, ccsnoophit, ccexclusivehit,
                l2load, l2state
    ); 

endinterface
`endif // COHERENCE_CTRL_IF_VH