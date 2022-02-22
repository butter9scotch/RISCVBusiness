import rv32i_types_pkg::*;

module memory_bfm(
    l1_cache_wrapper_if.cache cif,
    generic_bus_if.generic_bus bus_if
);

//TODO: NEEDS IMPLEMENTATION

    logic [15:0] tag;

    word_t memory [word_t]; //software fully associative cache

    int delay, cur_wait;

    initial begin
        tag = 16'hdada;
        delay = 1; //TODO: MAKE THIS CONFIGURABLE
        cur_wait = 0;

        forever begin
            @(posedge cif.CLK, negedge cif.nRST);
            bus_if.busy = '1;
            bus_if.rdata <= {tag, 16'h0bad};

            if(!cif.nRST) begin
                memory.delete();
                cur_wait = 0;
            end else if (bus_if.ren) begin
                if (cur_wait >= delay) begin
                    bus_if.busy = '0;
                    if (memory.exists(bus_if.addr)) begin
                        bus_if.rdata = memory[bus_if.addr];
                    end else begin
                        bus_if.rdata = {tag, bus_if.addr[15:0]};
                    end
                    cur_wait = 0;
                end else begin
                    cur_wait++;
                end
            end else if (bus_if.wen) begin
                if (cur_wait >= delay) begin
                    bus_if.busy = '0;
                    memory[bus_if.addr] = bus_if.wdata;
                    cur_wait = 0;
                end else begin
                    cur_wait++;
                end
            end else begin
                cur_wait = 0;
            end


        end
    end

    // always_ff @(posedge cif.CLK, negedge cif.nRST) begin
    //     if (!cif.nRST || !bus_if.ren || !bus_if.busy) begin
    //         bus_if.rdata <= {tag, 16'h0bad};
    //         bus_if.busy <= '1;
    //     end else begin
    //         bus_if.rdata <= {tag, bus_if.addr[15:0]};
    //         bus_if.busy <= '0;
    //     end
    // end


endmodule