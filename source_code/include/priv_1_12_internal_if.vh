/*
*   Copyright 2016 Purdue University
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*       http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*
*
*   Filename:     priv_1_12_internal_if.vh
*
*   Created by:   Hadi Ahmed
*   Email:        ahmed138@purdue.edu
*   Date Created: 03/27/2022
*   Description:  Interface for components within the privilege block v1.12
*/

`ifndef PRIV_1_12_INTERNAL_IF_VH
`define PRIV_1_12_INTERNAL_IF_VH

`include "component_selection_defines.vh"

interface priv_1_12_internal_if;
    import priv_types_1_12_pkg::*;
    import pma_types_1_12_pkg::*;
    import rv32i_types_pkg::*;

    csr_addr_t csr_addr; // CSR address to read
    priv_level_t curr_priv; // Current process privilege
    logic csr_write, csr_set, csr_clear; // Is the CSR currently being modified?
    logic invalid_csr; // Bad CSR address
    logic inst_ret; // signal when an instruction is retired
    word_t new_csr_val, old_csr_val; // new and old CSR values (atomically swapped)

    logic [RAM_ADDR_SIZE-1:0] addr; // Address to check
    logic ren, wen, xen; // RWX access type (xen is always high for i-fetches)
    pma_accwidth_t acc_width_type; // What is the memory trying to access

    pma_reg_t [5:0] pma_cfg_regs;
    logic pma_i_fault, pma_l_fault, pma_s_fault; // instruction, load, store -access fault

    modport csr (
        input csr_addr, curr_priv, csr_write, csr_set, csr_clear, new_csr_val, inst_ret,
        output old_csr_val, invalid_csr, pma_cfg_regs
    );

    modport pma (
        input addr, ren, wen, xen, pma_cfg_regs, acc_width_type,
        output pma_i_fault, pma_l_fault, pma_s_fault
    );

endinterface

`endif  // PRIV_1_12_INTERNAL_IF_VH
