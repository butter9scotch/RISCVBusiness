`ifndef OOO_EXECUTE_COMMIT_IF_VH
`define OOO_EXECUTE_COMMIT_IF_VH

interface ooo_execute_commit_if();

  import rv32i_types_pkg::*;

  logic halt_instr;
  logic csr_instr;
  logic instr_30;
  logic wen_au;
  logic wen_mu;
  logic wen_du;
  logic wen_ls;
  logic busy_au;
  logic busy_mu;
  logic busy_du;
  logic busy_ls;
  logic done_a;
  logic done_mu;
  logic done_du;
  logic done_ls;
  logic done_v;
  logic dren;
  logic mal_addr;
  logic dwen;
  logic breakpoint;
  logic ecall_insn;
  logic ret_insn;
  logic illegal_insn;
  logic invalid_csr;
  logic mal_insn;
  logic fault_insn;
  logic token;
  logic intr_seen;
  logic jump_instr;
  word_t jump_addr;
  logic branch_instr;
  logic prediction;
  logic branch_taken;
  logic [11:0] funct12;
  logic [11:0] imm_I;
  logic [11:0] imm_S;
  logic [12:0] imm_SB;
  logic [2:0] w_sel;
  logic [2:0] funct3;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] reg_rd_au;
  logic [4:0] reg_rd_mu;
  logic [4:0] reg_rd_du;
  logic [4:0] reg_rd_ls;
  logic [4:0] reg_rd_v;
  opcode_t opcode;
  word_t csr_rdata;
  word_t imm_UJ_ext;
  word_t imm_U;
  word_t instr;
  word_t wdata_au;
  word_t wdata_mu;
  word_t wdata_du;
  word_t wdata_ls;
  word_t wdata_v;
  word_t memory_addr;
  word_t pc;
  word_t br_resolved_addr;
  cpu_tracker_signals_t CPU_TRACKER;
  cpu_tracker_signals_t CPU_TRACKER_OUT;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_a;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_mu;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_du;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_ls;
  logic [$clog2(NUM_CB_ENTRY)-1:0] index_v;
  word_t pc_a;
  word_t pc_mu;
  word_t pc_du;
  word_t pc_ls;
  word_t pc4;
  logic exception_a;
  logic exception_mu;
  logic exception_du;
  logic exception_ls;
  logic exception_v;
  arith_control_signals_t arith_sigs;
  mult_control_signals_t mult_sigs;
  div_control_signals_t div_sigs;
  lsu_control_signals_t lsu_sigs;
  vector_struct_t v_sigs;
  logic mispredict;


  modport execute (
    output halt_instr, csr_instr, instr_30, wen_au, wen_mu, wen_du, 
           wen_ls, busy_au, busy_mu, busy_du, busy_ls, dren, 
           mal_addr, dwen, breakpoint, ecall_insn, ret_insn, illegal_insn, 
           invalid_csr, mal_insn, fault_insn, token, intr_seen, jump_instr, 
           jump_addr, branch_instr, prediction, branch_taken, funct12, imm_I, 
           imm_S, imm_SB, w_sel, funct3, rs1, rs2, 
           reg_rd_au, reg_rd_mu, reg_rd_du, reg_rd_ls, reg_rd_v, opcode, csr_rdata, 
           imm_UJ_ext, imm_U, instr, wdata_au, wdata_mu, wdata_du, 
           wdata_ls, wdata_v, memory_addr, pc, br_resolved_addr, CPU_TRACKER,
           index_a, index_mu, index_du, index_ls, index_v,
           pc_a, pc_mu, pc_du, pc_ls,
           exception_a, exception_mu, exception_du, exception_ls, exception_v, pc4,
           arith_sigs, mult_sigs, div_sigs, lsu_sigs, done_a, done_mu,
           done_du, done_ls, done_v, mispredict
  );

  modport commit (
    input halt_instr, csr_instr, instr_30, wen_au, wen_mu, wen_du, 
           wen_ls, busy_au, busy_mu, busy_du, busy_ls, dren, 
           mal_addr, dwen, breakpoint, ecall_insn, ret_insn, illegal_insn, 
           invalid_csr, mal_insn, fault_insn, token, intr_seen, jump_instr, 
           jump_addr, branch_instr, prediction, branch_taken, 
           funct12, imm_I, imm_S, imm_SB, w_sel, funct3, 
           rs1, rs2, reg_rd_au, reg_rd_mu, reg_rd_du, reg_rd_ls, reg_rd_v,
           opcode, csr_rdata, imm_UJ_ext, imm_U, instr, wdata_au, 
           wdata_mu, wdata_du, wdata_ls, wdata_v, memory_addr, pc, br_resolved_addr, index_a, index_mu, index_du, index_ls, index_v,  
           pc_a, pc_mu, pc_du, pc_ls, 
           exception_a, exception_mu, exception_du, exception_ls, exception_v, pc4, CPU_TRACKER,
           arith_sigs, mult_sigs, div_sigs, lsu_sigs, v_sigs, done_a, done_mu,
           done_du, done_ls, done_v, mispredict
  );

endinterface

`endif //OOO_EXECUTE_COMMIT_IF_VH
