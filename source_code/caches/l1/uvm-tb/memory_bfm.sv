module memory_bfm(
    l1_cache_wrapper_if.cache cif,
    generic_bus_if.generic_bus bus_if
);

//TODO: NEEDS IMPLEMENTATION

    always_comb begin
        bus_if.busy = '0;
        bus_if.rdata = 32'habcd_1234;
    end


endmodule