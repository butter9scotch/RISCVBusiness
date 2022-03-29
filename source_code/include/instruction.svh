// `ifndef TRANSACTION_SVH
// `define TRANSACTION_SVH

import rv32i_types_pkg::*;
// import rv32i_types_pkg::*;

class instruction;
    bit [4:0] vd;
    bit [4:0] vs1;
    bit [4:0] vs2;
    opcode_t op;

    bit vm;
    vfunct3_t [2:0] vfunct3;
    vopm_t vfunct6_vopm;
    vopi_t vfunct6_vopi;
    bit [31:0] instr; 

    function new();

    endfunction

    function bit [31:0] get_instr();
      return this.instr;
    endfunction

    function set_vfunct3(vfunct3_t [2:0] _vfunct3);
      this.vfunct3 = _vfunct3;
    endfunction

    function set_vopm(vopm_t _vopm); 
      this.vfunct6_vopm= _vopm;
    endfunction
    
    function set_vopi(vopi_t _vopi); 
      this.vfunct6_vopi= _vopi;
    endfunction

endclass //transaction

class RegReg extends instruction;

  function new(logic [5:0] funct6, bit vm, logic [4:0] vs2, logic [4:0] vs1, vfunct3_t funct3, logic [4:0] vd);
    // may need adjustment 
    this.vfunct6_vopi = funct6;
    this.vfunct6_vopm = funct6;
    this.vm  = vm;

    this.vs1 = vs1;
    this.vs2 = vs2;
    this.vd = vd;

    this.instr = {funct6, vm, vs2, vs1, funct3, vd, VECTOR};
  endfunction

endclass

class Vsetvl extends instruction;

  function new(logic [4:0] rs2, logic [4:0] rs1, logic [4:0] rd);
    this.instr = {7'b1000000,  rs2, rs1, 3'b111, rd, VECTOR};
  endfunction

endclass

class Vsetvli extends instruction;
  bit vma;
  bit vta;

  function new(sew_t sew, vlmul_t lmul, logic [4:0] rs1, logic [4:0] rd);
    vma = 0;
    vta = 0;
    this.instr = {1'b0, 5'd0, vma, vta, sew, lmul, rs1, 3'b111, rd, VECTOR};
  endfunction

endclass

class Vsetivli extends instruction;
  bit vma;
  bit vta;

  function new(sew_t sew, vlmul_t lmul, logic [4:0] imm5, logic [4:0] rd);
    vma = 0;
    vta = 0;
    this.instr = {2'b11, 4'd0, vma, vta, sew, lmul, imm5, 3'b111, rd, VECTOR};
  endfunction

endclass
// class randinstruction;

//   rand bit [4:0] vd;
//   rand bit [4:0] vs1;
//   rand bit [4:0] vs2;
//   rand opcode_t op;

//   bit vm;
//   vfunct3_t [2:0] vfunct3; 
//   vopm_t vfunct6_vopm;
//   vopi_t vfunct6_vopi;
//   bit [31:0] instr; 

//   constraint op_types { op inside {VECTOR}; }


//   function new ();
//   endfunction

//   function bit [31:0] get_instr();
//     return {vfunct6_vopi, vm, vs2, vs1, vfunct3, vd, op};
//   endfunction

// endclass //transaction

// `endif
