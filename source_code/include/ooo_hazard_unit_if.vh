`ifndef OOO_HAZARD_UNIT_IF_VH
`define OOO_HAZARD_UNIT_IF_VH

interface ooo_hazard_unit_if();

  import rv32i_types_pkg::word_t;
  import rv32i_types_pkg::scalar_fu_t;

  logic busy_div;
  logic busy_mul;
  logic data_hazard;

  logic pc_en;
  logic id_ex_flush;
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
  logic ex_mem_flush;
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
  logic npc_sel;
  logic stall;
  logic ifence_flush;
  logic csr_flush;
  logic insert_priv_pc;
  word_t priv_pc;
  logic if_id_flush;
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
  logic ex_comm_flush;

  modport decode (
    input pc_en, id_ex_flush, stall_au, stall_mu, stall_du, stall_ls, 
           stall_de, intr, 
    output halt, dflushed, iflushed, ifence_pc, fu_type, ifence
  );

  modport execute (
    input pc_en, ex_mem_flush, d_mem_busy, dmem_access, intr, intr_taken, 
    output load, stall_ex, jump, branch, mispredict, csr, 
           illegal_insn, breakpoint, env_m, ret, token, busy_au, 
           busy_mu, busy_du, busy_ls, brj_addr, csr_pc, 
           epc
  );

  modport fetch (
    input pc_en, npc_sel, stall, halt, ifence_flush, csr_flush, 
           insert_priv_pc, intr, intr_taken, brj_addr, ifence_pc, csr_pc, 
           priv_pc, if_id_flush, iren, 
    output i_mem_busy 
  );

  modport hazard_unit (
    input i_mem_busy, dren, dwen, d_mem_busy, jump, branch, 
           mispredict, load, halt, ifence, illegal_insn, fault_s, 
           fault_l, mal_s, mal_l, breakpoint, env_m, token, 
           mal_insn, fault_insn, ret, intr_taken, stall_ex, div_e, 
           mul_e, busy_au, busy_mu, busy_du, busy_ls, busy_all, 
           badaddr_d, badaddr_i, epc,  fu_type, stall_de, busy_div,
           busy_mul, rob_full, data_hazard, dflushed, iflushed,
    output pc_en, if_if_flush, if_id_flush, id_ex_flush, csr, iren, 
           ex_mem_flush, npc_sel, dmem_access, stall, ifence_flush, csr_flush, 
           insert_priv_pc, intr, stall_au, stall_mu, stall_du, stall_ls, 
           stall_all, priv_pc, ex_comm_flush
  );

  modport commit (
    output fault_l, mal_l, fault_s, mal_s, mal_insn, fault_insn, 
           intr_taken, breakpoint, env_m, ret, illegal_insn, token, 
           epc, badaddr_d, badaddr_i, rob_full, pc_en, ex_comm_flush
  );

  modport memory (
    input ex_mem_flush, pc_en, dmem_access,  
    output d_mem_busy, dren, dwen
  );

  modport cb (
    output rob_full
  );

endinterface

`endif //OOO_HAZARD_UNIT_IF_VH
