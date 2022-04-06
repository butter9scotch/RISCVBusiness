#!/bin/bash
irun $1 -access +rwc +nctimescale+1ns/1ns -coverage all -covoverwrite -incdir  ~/socet_uvm/RISCVBusiness/source_code/include/ ~/socet_uvm/RISCVBusiness/source_code/packages/rv32i_types_pkg.sv  l2_cache.sv ../memory_arbiter.sv  tb/tb_l2_cache.sv
