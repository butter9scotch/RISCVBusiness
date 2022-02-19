module memory_bfm(
    l1_cache_wrapper_if.cache cif,
    generic_bus_if.generic_bus bus_if
);

//TODO: NEEDS IMPLEMENTATION

    logic [31:0] count;

    always_ff @(posedge cif.CLK, negedge cif.nRST) begin
        if (!cif.nRST) begin
            bus_if.rdata <= 32'hdada_0000;
            bus_if.busy <= '1;
        end else if (bus_if.ren) begin
            bus_if.rdata <= bus_if.rdata + 1;
            bus_if.busy <= '0;
        end else begin
            bus_if.rdata <= bus_if.rdata;
            bus_if.busy <= bus_if.busy;
        end
    end


endmodule