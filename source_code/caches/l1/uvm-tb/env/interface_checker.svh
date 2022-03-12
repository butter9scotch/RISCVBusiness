`ifndef INTERFACE_CHECKER_SVH
`define INTERFACE_CHECKER_SVH

module interface_checker(
    l1_cache_wrapper_if.cache cif,
    generic_bus_if.generic_bus cpu_if,
    generic_bus_if.generic_bus mem_if
);

    //FIXME: L1 RESPONSE WITHOUT REQUEST
    //FIXME: we have busy low when wen/ren are asserted for first cycle (request cycle)
    // this doesn't seem like an issue we need to check (or that is even an issue)
    // assert property (@(posedge cif.CLK) !(cpu_if.ren || cpu_if.wen) && !cpu_if.busy);

endmodule: interface_checker


`endif