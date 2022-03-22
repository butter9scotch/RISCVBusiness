`ifndef MEMORY_BFM_SVH
`define MEMORY_BFM_SVH

`include "cache_env_config.svh"

`include "uvm_macros.svh"

`include "dut_params.svh"

import uvm_pkg::*;
import rv32i_types_pkg::*;

class memory_bfm extends uvm_component;
    `uvm_component_utils(memory_bfm)

    virtual l1_cache_wrapper_if cif;
    virtual generic_bus_if bus_if;

    cache_env_config env_config;

    word_t mem[word_t]; // initialized memory array
    word_t mmio[word_t]; // initialized memory mapped array

    function new(string name = "memory_bfm", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // get config from database
        if( !uvm_config_db#(cache_env_config)::get(this, "", "env_config", env_config) ) begin
            `uvm_fatal(this.get_name(), "env config not registered to db")
        end

        // get interface from database
        if( !uvm_config_db#(virtual l1_cache_wrapper_if)::get(this, "", "cpu_cif", cif) ) begin
            `uvm_fatal($sformatf("%s/cif", this.get_name()), "No virtual interface specified for this test instance");
		end
        if( !uvm_config_db#(virtual generic_bus_if)::get(this, "", "l1_bus_if", bus_if) ) begin
            `uvm_fatal($sformatf("%s/mem_bus_if", this.get_name()), "No virtual interface specified for this test instance");
		end

    endfunction: build_phase


    virtual task run_phase(uvm_phase phase);
        // initial values on bus
        bus_if.busy = '0;
        bus_if.rdata = 32'hbad0_bad0; 

        forever begin
            @(posedge cif.CLK);
            #(1); // propagation delay
            if (bus_if.addr < `NONCACHE_START_ADDR) begin
                if (bus_if.ren) begin
                    mem_read();
                end else if (bus_if.wen) begin
                    mem_write();
                end
            end else if (bus_if.addr >= `NONCACHE_START_ADDR) begin
                if (bus_if.ren) begin
                    mmio_read();
                end else begin
                    mmio_write();
                end
            end
        end
    endtask: run_phase

    task mem_read();
        int count;
        while(bus_if.ren) begin
            @(negedge cif.CLK); // wait for propigation delay
            bus_if.busy = '1;
            if (mem.exists(bus_if.addr)) begin
                bus_if.rdata = mem[bus_if.addr];
            end else begin
                bus_if.rdata = {env_config.mem_tag, bus_if.addr[15:0]}; // return non-initialized data
            end
            count = 1;
            while(count < env_config.mem_latency) begin
                @(negedge cif.CLK);
                count++;
            end
            bus_if.busy = '0;
        end
    endtask: mem_read

    task mem_write();
        int count;
        while(bus_if.wen) begin
            @(negedge cif.CLK); // wait for propigation delay
            bus_if.busy = '1;
            mem[bus_if.addr] = bus_if.wdata;
            
            count = 1;
            while(count < env_config.mem_latency) begin
                @(negedge cif.CLK);
                count++;
            end
            bus_if.busy = '0;
        end
    endtask: mem_write

    task mmio_read();
        int count;
        while(bus_if.ren || '1) begin //FIXME: REMOVE THE || '1 ONCE DESIGN TEAM FIXES BUG
            @(negedge cif.CLK); // wait for propigation delay
            bus_if.busy = '1;
            //TODO: COME UP WITH SOME MEANINGFUL DATA TO PUT FOR MMIO, MAYBE SIMULATE A PERIFERAL REGISTER
            bus_if.rdata = {env_config.mmio_tag, bus_if.addr[15:0]};
            // if (mmio.exists(bus_if.addr)) begin
            //     bus_if.rdata = mmio[bus_if.addr];
            // end else begin
            //     bus_if.rdata = {env_config.mmio_tag, bus_if.addr[15:0]}; // return non-initialized data
            // end
            count = 1;
            while(count < env_config.mmio_latency) begin
                @(negedge cif.CLK);
                count++;
            end
            bus_if.busy = '0;
        end
    endtask: mmio_read

    task mmio_write();
        int count;
        while(bus_if.wen || '1) begin //FIXME: REMOVE THE || '1 ONCE DESIGN TEAM FIXES BUG
            @(negedge cif.CLK); // wait for propigation delay
            bus_if.busy = '1;
            // mmio[bus_if.addr] = bus_if.wdata; //TODO: DO SOMETHING MORE MEANINGFUL FOR WRITING TO MMIO, REGISTER MODEL?
            
            count = 1;
            while(count < env_config.mmio_latency) begin
                @(negedge cif.CLK);
                count++;
            end
            bus_if.busy = '0;
        end
    endtask: mmio_write

endclass: memory_bfm

`endif