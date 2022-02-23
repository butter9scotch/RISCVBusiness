module memory_bfm(
    l1_cache_wrapper_if.cache cif,
    generic_bus_if.generic_bus bus_if
);

//TODO: NEEDS IMPLEMENTATION

    logic [15:0] tag;
    assign tag = 16'hdada;

    // always_ff @(posedge cif.CLK, negedge cif.nRST) begin
    //     if (!cif.nRST || !bus_if.ren || !bus_if.busy) begin
    //         bus_if.rdata <= {tag, 16'h0bad};
    //         bus_if.busy <= '1;
    //     end else begin
    //         bus_if.rdata <= {tag, bus_if.addr[15:0]};
    //         bus_if.busy <= '0;
    //     end
    // end

    always_comb begin
        bus_if.rdata <= {tag, bus_if.addr[15:0]};
        bus_if.busy <= '0;
    end


endmodule