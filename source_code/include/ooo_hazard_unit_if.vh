`ifndef OOO_HAZARD_UNIT_IF_VH
`define OOO_HAZARD_UNIT_IF_VH

interface ooo_hazard_unit_if();

  import rv32i_types_pkg::word_t;
  import rv32i_types_pkg::scalar_fu_t;

  logic busy_div;
  logic busy_mul;
  logic data_hazard;

  logic pc_en;
  logic decode_execute_flush;
  logic stall_au;
  logic stall_mu;
  logic stall_du;
  logic stall_ls;
  logic stall_all;
  logic intr;
  logic halt;
  logic dflushed;
  logic iflushed;
  word_t ifence_pc;
  logic loadstore_flush;
  logic d_mem_busy;
  logic dmem_access;
  logic intr_taken;
  logic load;
  logic stall_ex;
  logic stall_de;
  logic jump;
  logic branch;
  logic mispredict;
  logic csr;
  logic illegal_insn;
  logic breakpoint;
  logic env_m;
  logic ret;
  logic token;
  word_t brj_addr;
  word_t csr_pc;
  word_t epc;
  word_t pc_ex;
  word_t pc_fe;
  logic npc_sel;
  logic ifence_flush;
  logic csr_flush;
  logic insert_priv_pc;
  word_t priv_pc;
  logic fetch_decode_flush;
  logic iren;
  logic i_mem_busy;
  logic dren;
  logic dwen;
  logic ifence;
  logic fault_s;
  logic fault_l;
  logic mal_s;
  logic mal_l;
  logic mal_insn;
  logic fault_insn;
  logic div_e;
  logic mul_e;
  logic busy_all;
  word_t badaddr_d;
  word_t badaddr_i;
  logic if_if_flush;
  //NEW SIGNALS
  logic busy_au;
  logic busy_mu;
  logic busy_du;
  logic busy_ls;
  scalar_fu_t fu_type;
  logic rob_full;
  logic execute_commit_flush;
  logic rd_busy;
  logic rs1_busy;
  logic rs2_busy;
  logic instr_imm;
  logic [1:0] source_a_sel, source_b_sel;
  logic wen; // we need this to know if we need to stall for rd
  logic stall_commit;
  logic stall_fetch_decode;
  logic busy_decode;
  logic rob_empty;
  logic hazard;
  logic mispredict_ff;
  logic wb_port_conflict;
  logic csr_ready;
  logic stall_csr;
  logic stall_cb;
  logic instr_wait_ihit;
  logic update_pc_wait_ihit;
  logic ifence_decode;
  logic ifence_ex;
  logic ifence_cache_flushing;
  word_t resolved_pc;


  modport decode (
    input pc_en, decode_execute_flush, stall_au, stall_mu, stall_du, stall_ls, csr_flush,
           stall_de, intr, stall_fetch_decode, data_hazard, hazard, npc_sel, rob_empty, csr_ready,
    output halt, dflushed, iflushed, fu_type, ifence, rd_busy, ifence_ex,
           rs1_busy, rs2_busy, source_a_sel, source_b_sel, wen, stall_ex, busy_decode, wb_port_conflict, stall_csr, instr_wait_ihit, ifence_decode
  );

  modport execute (
    input loadstore_flush, pc_en, execute_commit_flush, dmem_access, intr, intr_taken, stall_commit, update_pc_wait_ihit,
    output load, stall_ex, jump, branch, mispredict, mispredict_ff, csr, 
           illegal_insn, breakpoint, env_m, ret, token, busy_au, 
           busy_mu, busy_du, busy_ls, brj_addr, csr_pc, resolved_pc,
           epc, pc_ex, mal_l, mal_s, badaddr_d, mal_insn, d_mem_busy, dren, dwen, csr_ready, instr_wait_ihit, ifence_ex, ifence_cache_flushing, ifence_flush, ifence_pc
  );

  modport fetch (
    input pc_en, npc_sel, halt, ifence_flush, csr_flush, 
           insert_priv_pc, intr, intr_taken, brj_addr, ifence_pc, csr_pc, stall_csr,
           priv_pc, fetch_decode_flush, iren, stall_fetch_decode, busy_decode, pc_fe, update_pc_wait_ihit, ifence_cache_flushing,
    output i_mem_busy 
  );

  modport hazard_unit (
    input i_mem_busy, dren, dwen, d_mem_busy, jump, branch, 
           mispredict, mispredict_ff, load, halt, ifence, illegal_insn, fault_s, 
           fault_l, mal_s, mal_l, breakpoint, env_m, token, 
           mal_insn, fault_insn, ret,  div_e, instr_wait_ihit,
           mul_e, busy_au, busy_mu, busy_du, busy_ls, busy_all, 
           badaddr_d, badaddr_i, epc,  fu_type,  busy_div,
           busy_mul, rob_full, rob_empty, data_hazard, hazard, dflushed, iflushed,
           rs1_busy, rs2_busy, rd_busy, source_a_sel, source_b_sel, wen, ifence_ex, ifence_flush, ifence_cache_flushing,
          busy_decode, pc_ex, wb_port_conflict, pc_fe, csr_ready, resolved_pc, ifence_decode,
    output pc_en, if_if_flush, fetch_decode_flush, decode_execute_flush, csr, iren, 
           loadstore_flush, npc_sel, dmem_access, csr_flush, 
           insert_priv_pc, intr, stall_au, stall_mu, stall_du, stall_ls, 
           stall_all, priv_pc, execute_commit_flush, stall_commit, stall_ex, stall_de,
          stall_fetch_decode, intr_taken, stall_cb, update_pc_wait_ihit
  );

  modport commit (
    input stall_commit,
    output fault_l, fault_s, fault_insn, 
           intr_taken, breakpoint, env_m, token, 
           epc, badaddr_i, rob_full, rob_empty, pc_en, execute_commit_flush
  );

  modport memory (
    input loadstore_flush, pc_en, dmem_access, stall_ls,
    output d_mem_busy, dren, dwen, busy_ls
  );

  modport cb (
    input npc_sel, stall_cb,
    output rob_full, rob_empty
  );

endinterface

`endif //OOO_HAZARD_UNIT_IF_VH
