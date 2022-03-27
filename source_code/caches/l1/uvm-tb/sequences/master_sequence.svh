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
*   Filename:     master_sequence.svh
*
*   Created by:   Mitch Arndt
*   Email:        arndt20@purdue.edu
*   Date Created: 03/27/2022
*   Description:  Sequence that randomly interleaves all other sequences
*/

`ifndef MASTER_SEQUENCE_SVH
`define MASTER_SEQUENCE_SVH

import uvm_pkg::*;
import rv32i_types_pkg::*;

`include "uvm_macros.svh"

`include "dut_params.svh"

`include "nominal_sequence.svh"
`include "index_sequence.svh"
`include "evict_sequence.svh"
`include "mmio_sequence.svh"

`include "cpu_transaction.svh"

class sub_master_sequence;
  rand int nom_max_n;
  rand int evt_max_n;
  rand int idx_max_n;
  rand int mmio_max_n;

  //TODO: CHANGE THESE TO MORE CONFIGURABLE PARAMS
  constraint max {
    nom_max_n > 0; nom_max_n < 10;
    idx_max_n > 0; idx_max_n < 10; 
    evt_max_n > 0; evt_max_n < 10; 
    mmio_max_n > 0; mmio_max_n < 10;
  }

  function void show();
    `uvm_info("sub_master_seq", $sformatf("evt_max_n: %0d, nom_max_n: %0d, mmio_max_n: %0d", evt_max_n, nom_max_n, mmio_max_n), UVM_LOW);
  endfunction
endclass: sub_master_sequence

class master_sequence extends uvm_sequence #(cpu_transaction);
  `uvm_object_utils(master_sequence)
  `uvm_declare_p_sequencer(cpu_sequencer)

  rand int iterations;

  constraint range {
    iterations > 0; iterations < 10;
  }

  sub_master_sequence seq_param;

  nominal_sequence nom_seq;
  index_sequence idx_seq;
  evict_sequence evt_seq;
  mmio_sequence mmio_seq;

  function new(string name = "");
    super.new(name);
    nom_seq = nominal_sequence::type_id::create("nom_seq");
    idx_seq = index_sequence::type_id::create("idx_seq");
    evt_seq = evict_sequence::type_id::create("evt_seq");
    mmio_seq = mmio_sequence::type_id::create("mmio_seq");
    seq_param = new();
  endfunction: new

  function void sub_randomize();
    //randomize sub-sequences
    if(!nom_seq.randomize() with {
      N inside {[0:seq_param.nom_max_n]};
      }) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end

    if(!idx_seq.randomize() with {
      N inside {[0:seq_param.idx_max_n]};
      }) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end

    if(!evt_seq.randomize() with {
      N inside {[0:seq_param.nom_max_n]};
      }) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end

    if(!mmio_seq.randomize() with {
      N inside {[0:seq_param.mmio_max_n]};
      }) begin
      `uvm_fatal("Randomize Error", "not able to randomize")
    end
  endfunction

  task body();
    cpu_transaction req_item;
    uvm_sequence #(cpu_transaction) seq_list [$];
    seq_list.push_back(nom_seq);
    seq_list.push_back(idx_seq);
    seq_list.push_back(evt_seq);
    seq_list.push_back(mmio_seq);

    `uvm_info(this.get_name(), $sformatf("running %0d iterations", iterations), UVM_LOW)

    repeat(iterations) begin
      if(!seq_param.randomize()) begin
        `uvm_fatal("Randomize Error", "not able to randomize")
      end
      seq_param.show();   // display sequence parameters

      seq_list.shuffle(); // reorder list elements to get random ordering
      sub_randomize();    // randomize sub sequences

      for (int i = 0; i < seq_list.size(); i++) begin
        seq_list[i].start(p_sequencer);
      end
    end
  endtask: body
endclass: master_sequence

`endif