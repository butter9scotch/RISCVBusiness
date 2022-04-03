
`include "element_counter_if.vh"

module element_counter # (
  parameter NUM_COUNTERS = 1
) (
  input logic CLK, nRST,
  element_counter_if ele_if
);

  genvar i;

  generate
    for (i = 0; i < NUM_COUNTERS; i = i + 1) begin
      counter CNT (
        .CLK(CLK), 
        .nRST(nRST),
        .vstart(ele_if.vstart[i]), 
        .vl(ele_if.vl[i]),
        .stall(ele_if.stall[i]), 
        .ex_return(ele_if.ex_return[i]), 
        .start(ele_if.start[i]), 
        .clear(ele_if.clear[i]), 
        .busy_ex(ele_if.busy_ex[i]), 
        .offset(ele_if.offset[i]),
        .done(ele_if.done[i]), 
        .next_done(ele_if.next_done[i])
      );
    end
  endgenerate

endmodule
