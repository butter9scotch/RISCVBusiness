`include "ooo_hazard_unit_if.vh"
`include "completion_buffer_if.vh"

module ooo_hazard_unit (
  ooo_hazard_unit_if.hazard_unit hazard_if,
  prv_pipeline_if.hazard  prv_pipe_if,
  completion_buffer_if.hu cb_if
);

  logic wait_for_imem;
  logic wait_for_dmem;
  logic branch_jump;
  logic load_stall;
  logic e_fetch_stage, e_decode_stage, e_execute_stage;
  logic intr_e_flush, intr_execption;

  //Incrementing PC only when instruction has been fetched
  assign wait_for_imem = hazard_if.iren & hazard_if.i_mem_busy;
  assign wait_for_dmem = hazard_if.dmem_access & hazard_if.d_mem_busy;  

  //BUSY
  // assign hazard_if.busy_ls = hazard_if.dren | hazard_if.dwen; 
  // input hazard_if.busy_au 
  // input hazard_if.busy_mul 
  // input hazard_if.busy_div
  // output hazard_if.stall_fetch
  // output hazard_if.stall_de 
  // output stall_ex -- stall all functional unit latches
  // input data_hazard- comes from rfif bit vector bc of RAW/WAW
  // Instruction latch enable
  // rob_full -- reorder buffer full
  logic pc_stall;
  assign pc_stall = wait_for_imem | hazard_if.stall_de ;
  assign hazard_if.pc_en =  ~pc_stall;

  //FETCH_DECODE
  assign hazard_if.stall_au = (hazard_if.fu_type == ARITH_S) & hazard_if.busy_au;
  assign hazard_if.stall_du = (hazard_if.fu_type == DIV_S) & hazard_if.busy_div;
  assign hazard_if.stall_mu = (hazard_if.fu_type == MUL_S) & hazard_if.busy_mul;
  assign hazard_if.stall_ls = (hazard_if.fu_type == LOADSTORE_S) & hazard_if.busy_ls;

  logic structural_hazard;
  assign structural_hazard = hazard_if.stall_au |  hazard_if.stall_du | hazard_if.stall_mu |  hazard_if.stall_ls;

  assign fetch_decode_stall = hazard_if.rob_full | hazard_if.data_hazard | hazard_if.ifence | structural_hazard;

  
  //Branch jump 
  assign branch_jump = hazard_if.jump || (hazard_if.branch && hazard_if.mispredict);
  assign hazard_if.npc_sel = branch_jump & ~intr_execption;

  //Pipe flush logic 
  assign hazard_if.csr_flush = hazard_if.csr;
  assign hazard_if.ifence_flush = hazard_if.ifence && (~hazard_if.dflushed || ~hazard_if.iflushed);
  assign hazard_if.if_id_flush  = branch_jump | hazard_if.ifence_flush | hazard_if.csr | intr_e_flush;
  assign hazard_if.id_ex_flush  = branch_jump | hazard_if.ifence_flush | hazard_if.csr | intr_e_flush;


 // RAW hazard because of load -> Stall the pipe
  //assign load_stall = (((hazard_if.reg_rd == hazard_if.reg_rs1) || (hazard_if.reg_rd == hazard_if.reg_rs2)) & hazard_if.load) ? 1'b1 : 1'b0;
  assign hazard_if.stall = load_stall & ~hazard_if.csr & ~hazard_if.ifence_flush & ~intr_e_flush | hazard_if.stall_ex;

 //Exceptions
  //assign e_fetch_stage       = hazard_if.fault_insn | hazard_if.mal_insn | hazard_if.fault_l | hazard_if.fault_s; REMOVE?
  //assign e_decode_stage      = hazard_if.illegal_insn | hazard_if.breakpoint | hazard_if.env_m;                   REMOVE?
  //assign e_execute_stage     = hazard_if.mal_l | hazard_if.mal_s;                                                 REMOVE?
  assign e_commit_stage     = hazard_if.fault_insn | hazard_if.mal_insn | hazard_if.fault_l | 
                              hazard_if.fault_s | hazard_if.illegal_insn | hazard_if.breakpoint | 
                              hazard_if.env_m | hazard_if.mal_l | hazard_if.mal_s;

  /* Send Exception notifications to Prv Block */
  assign prv_pipe_if.wb_enable    = hazard_if.jump |hazard_if.branch; //Because 2 stages
  assign prv_pipe_if.fault_insn   = hazard_if.fault_insn;
  assign prv_pipe_if.mal_insn     = hazard_if.mal_insn;//pc address [2:0] != 'b00
  assign prv_pipe_if.illegal_insn = hazard_if.illegal_insn;//opcode illegal
  assign prv_pipe_if.fault_l      = hazard_if.fault_l;
  assign prv_pipe_if.mal_l        = hazard_if.mal_l;//memory load addr incorrect
  assign prv_pipe_if.fault_s      = hazard_if.fault_s;
  assign prv_pipe_if.mal_s        = hazard_if.mal_s;//memory store addr incorrect
  assign prv_pipe_if.breakpoint   = hazard_if.breakpoint; 
  assign prv_pipe_if.env_m        = hazard_if.env_m;
  assign prv_pipe_if.ret          = hazard_if.ret;
  assign prv_pipe_if.ex_rmgmt     = 1'b0;
  
  assign prv_pipe_if.epc     =   hazard_if.epc;
  assign prv_pipe_if.badaddr = (hazard_if.mal_insn | hazard_if.fault_insn) ? hazard_if.badaddr_i : 
                               hazard_if.badaddr_d;  
  
  assign hazard_if.intr = ~e_commit_stage & prv_pipe_if.intr;
  
  assign hazard_if.insert_priv_pc = prv_pipe_if.insert_pc;
  assign hazard_if.priv_pc        = prv_pipe_if.priv_pc;
  assign hazard_if.iren           = 1'b1; 

  //Pick up here

  assign prv_pipe_if.pipe_clear   =   e_execute_stage | e_decode_stage | e_fetch_stage| hazard_if.intr_taken;

  assign intr_execption = e_fetch_stage | e_decode_stage | e_execute_stage | hazard_if.intr_taken | prv_pipe_if.ret;
  assign intr_e_flush = intr_execption;
  assign pc_en = 1; //TODO

  
endmodule
