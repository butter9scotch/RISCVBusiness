import uvm_pkg::*;
`include "uvm_macros.svh"

`include "tb_FPU_transaction.svh"

class FPU_sequence extends uvm_sequence #(FPU_transaction);
  `uvm_object_utils(FPU_sequence)

  localparam ADD = 7'b0000000;
  localparam MUL = 7'b0001000;
  localparam SUB = 7'b0000100; 

  function new(string name = "");
    super.new(name);
  endfunction: new

  task body();
    FPU_transaction req_item;
    req_item = FPU_transaction::type_id::create("req_item");
    //~~~~~~~~~~~~~~~~
    //load to register 0 and read test case
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 1;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //~~~~~~~~~~~~~~~~
    //add test case
    //load to regiseer 0
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'h0001;
    finish_item(req_item);

    //load to register 1
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = 5'd1;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //add operation to register 2
    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 0;
    req_item.f_rd = 5'd2;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = 5'd1;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = ADD;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    // read from register 2
    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 1;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = 5'd2;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //~~~~~~~~~~~~~~~~
    //mul test case
    //load to regiseer 0
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'h0001;
    finish_item(req_item);

    //load to register 1
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = 5'd1;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //mul operation to register 2
    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 0;
    req_item.f_rd = 5'd2;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = 5'd1;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = MUL;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    // read from register 2
    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 1;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = 5'd2;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //~~~~~~~~~~~~~~~~
    //sub test case
    //load to regiseer 0
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'h0001;
    finish_item(req_item);

    //load to register 1
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = 5'd1;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //add operation to register 2
    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 0;
    req_item.f_rd = 5'd2;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = 5'd1;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = ADD;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    // read from register 2
    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 1;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = 5'd2;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //~~~~~~~~~~~~~~~~
    //mul test case
    //load to regiseer 0
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'h0001;
    finish_item(req_item);

    //load to register 1
    start_item(req_item);
    req_item.f_LW = 1;
    req_item.f_SW = 0;
    req_item.f_rd = 5'd1;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = '0;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //mul operation to register 2
    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 0;
    req_item.f_rd = 5'd2;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = 5'd1;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = SUB;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    // read from register 2
    start_item(req_item);
    req_item.f_LW = 0;
    req_item.f_SW = 1;
    req_item.f_rd = '0;
    req_item.f_rs1 = '0;
    req_item.f_rs2 = 5'd2;
    req_item.f_frm_in = '0;
    req_item.f_funct_7 = '0;
    req_item.dload_ext = 32'habcd;
    finish_item(req_item);

    //~~~~~~~~~~~~~~~~
    //random test case

    repeat(100) begin
      logic [4:0] rs1; //register selection 1. Select operand 1 from a register
      logic [4:0] rs2; //register selection 2. Select operand 2 from a register
      logic [4:0] rd;  // register destination. Select which register to be written
    
      // load 1
      start_item(req_item);
      req_item.mode = req_item.LOAD;
      if(!req_item.randomize()) begin
        `uvm_fatal("FPU_seq", "not able to randomize")
      end
      rs1 = req_item.f_rd;
      finish_item(req_item);

      // load 2
      start_item(req_item);
      req_item.mode = req_item.LOAD;
      while(req_item.f_rd == rs1) begin
        if(!req_item.randomize()) begin
          `uvm_fatal("FPU_seq", "not able to randomize")
        end
      end
      rs2 = req_item.f_rd;
      finish_item(req_item);

      // operation
      start_item(req_item);
      req_item.mode = req_item.OP;
      if(!req_item.randomize()) begin
        `uvm_fatal("FPU_seq", "not able to randomize")
      end
      req_item.f_rs1 = rs1;
      req_item.f_rs2 = rs2;
      rd = req_item.f_rd;
      finish_item(req_item);

      // store
      start_item(req_item);
      req_item.mode = req_item.STR;
      if(!req_item.randomize()) begin
        `uvm_fatal("FPU_seq", "not able to randomize")
      end
      req_item.f_rs2 = rd;
      finish_item(req_item);
    end

  endtask: body
endclass //FPU_sequence

class FPU_sequencer extends uvm_sequencer#(FPU_transaction);

   `uvm_component_utils(FPU_sequencer)
 
   function new(input string name= "FPU_sequencer", uvm_component parent=null);
      super.new(name, parent);
   endfunction : new

endclass : FPU_sequencer
