#!/bin/bash
mkdir testbench
for i in source/tb_*
do
        dest=$(echo $i | cut -d '/' -f2)
        cp $i testbench/$dest
        new_dest=$(echo $dest | cut -d '_' --fields=2- | cut -d '.' -f1)"_tb.sv"
        mv testbench/$dest testbench/$new_dest
done
