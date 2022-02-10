
`ifndef PIPE5_HAZARD_UNIT_IF_VH
`define PIPE5_HAZARD_UNIT_IF_VH

interface pipe5_hazard_unit_if();

    import rv32i_types_pkg::word_t;
    
    logic pc_en, i_mem_busy, iren, load;
    logic d_mem_busy, dren, dwen, dmem_access;
    logic npc_sel, if_id_flush, id_ex_flush, ex_mem_flush;
    logic jump, branch, mispredict;
    logic if_if_flush;
    logic [31:0] brj_addr, ifence_pc, csr_pc;
    logic [4:0] reg_rd, reg_rs1, reg_rs2;
    logic halt;
    logic stall;
    logic dflushed, iflushed, ifence, ifence_flush;
    logic csr, csr_flush;
    logic illegal_insn, fault_l, mal_l, fault_s, mal_s, breakpoin;
    logic env_m, ret, token, breakpoint; 
    logic mal_insn, fault_insn;
    word_t badaddr_d, badaddr_i, epc;
    word_t priv_pc;
    logic  insert_priv_pc;
    logic  intr_taken, intr;
    logic stall_ex;
    logic div_e, mul_e;

    
    modport hazard_unit(
        input i_mem_busy,dren, dwen, d_mem_busy,
              brj_addr, jump, branch, mispredict,
              reg_rs1, reg_rs2, reg_rd,
              load,
              halt, 
              dflushed, iflushed, ifence,
              illegal_insn, fault_s, fault_l, mal_s, mal_l, breakpoint, env_m,
              badaddr_d, badaddr_i, epc, token, mal_insn, fault_insn, ret,intr_taken,
              stall_ex, div_e, mul_e,

       output pc_en, if_if_flush, if_id_flush, id_ex_flush,csr, iren,
              ex_mem_flush, npc_sel, dmem_access, stall, ifence_flush, csr_flush,
              priv_pc, insert_priv_pc, intr
    );
    modport fetch1(
        input pc_en, npc_sel, brj_addr, stall, halt, ifence_flush, ifence_pc,
              csr_flush, csr_pc, insert_priv_pc, priv_pc, intr, intr_taken
    );
    modport fetch2(
        output i_mem_busy, stall, 
        input pc_en, if_id_flush, iren, intr
    );
    modport decode(
        input pc_en, id_ex_flush, stall,intr,
        output halt, reg_rs1, reg_rs2
    );
    modport execute(
        input pc_en, ex_mem_flush, d_mem_busy, dmem_access,intr,intr_taken, 
        output reg_rd, load, stall_ex, div_e, mul_e
    );
    modport memory(
        input pc_en,intr,
        output brj_addr, jump, branch, mispredict, dren, dwen, d_mem_busy,
               dflushed, iflushed, ifence, ifence_pc, csr, csr_pc,
               illegal_insn, fault_l, mal_l, fault_s, mal_s, breakpoint,
               env_m, ret, badaddr_d, badaddr_i, epc, token,
               mal_insn, fault_insn, intr_taken
               
    );


endinterface
`endif
