`ifndef RV32V_HAZARD_UNIT_IF_VH
`define RV32V_HAZARD_UNIT_IF_VH

interface rv32v_hazard_unit_if;

  logic stall_f1, flush_f1, stall_f2, flush_f2, stall_dec, flush_dec, stall_ex, flush_ex, stall_mem, flush_mem, csr_update, busy_dec, busy_ex, busy_mem, busy_f1, busy_f2;
  logic exception_mem;
  logic next_busy_ex;
  logic decode_ena, execute_ena, memory_ena, writeback_ena;
  logic v_decode_done;
  logic exception_v;
  logic v_busy; // This is the latch in the v decode stage that will act as the vector stall signal
  logic v_done; // This is the done signal from rob that is propagated from element counter
  logic next_v_done;

  modport hazard_unit (
    input csr_update, busy_dec, busy_ex, busy_mem, decode_ena, execute_ena, memory_ena, writeback_ena, v_busy, v_done,
    output stall_dec, flush_dec, stall_ex, flush_ex, stall_mem, flush_mem,
    flush_f1, stall_f1, flush_f2, stall_f2, v_decode_done
  );

  modport fetch1 (
    input stall_f1, flush_f1,
    output busy_f1
  );

  modport fetch2 (
    input stall_f2, flush_f2,
    output busy_f2
  );

  modport decode (
    input exception_v, stall_dec, flush_dec, busy_ex, busy_mem, next_busy_ex, csr_update, v_busy,
    output busy_dec, decode_ena
  );

  modport execute (
    input stall_ex, flush_ex, 
    output busy_ex, next_busy_ex, execute_ena, v_decode_done
  );

  modport memory (
    input stall_mem, flush_mem, v_done, next_v_done,
    output csr_update, busy_mem, exception_mem, memory_ena
  );

  modport writeback (
    output writeback_ena
  );
  modport rob (
    output v_done, next_v_done
  );

endinterface

`endif // RV32V_HAZARD_UNIT_IF_VH
