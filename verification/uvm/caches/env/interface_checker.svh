/*
*   Copyright 2022 Purdue University
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
*   Filename:     interface_checker.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  Checks for invalid combinations of input/output signals for the DUT
*/

`ifndef INTERFACE_CHECKER_SVH
`define INTERFACE_CHECKER_SVH

module interface_checker(
    cache_if.cache d_cif,
    generic_bus_if.generic_bus d_cpu_if,
    generic_bus_if.generic_bus mem_if
);

    //FIXME: L1 RESPONSE WITHOUT REQUEST
    //FIXME: we have busy low when wen/ren are asserted for first cycle (request cycle)
    // this doesn't seem like an issue we need to check (or that is even an issue)
    // assert property (@(posedge i_cif.CLK) !(cpu_if.ren || cpu_if.wen) && !cpu_if.busy);
    // assert 
    //     property (@(posedge i_cif.CLK) cpu_if.busy |-> ##2 (cpu_if.ren || cpu_if.wen))
    //     else $fatal(1, "fatal error");
    // assert property (@(posedge mem_if.busy) mem_if.ren || mem_if.wen);
    // assert property(@(posedge i_cif.CLK) cpu_if.byte_en != 32'hff00ff00);
    assert 
        property(@(posedge d_cif.CLK) d_cif.flush_done |-> (d_cif.flush))
        else $fatal(1, "'d_cif.flush_done' should never be asserted without a cpu flush request");
    //TODO: IMPLEMENT CHECK FOR VALID BYTE_EN
endmodule: interface_checker


`endif