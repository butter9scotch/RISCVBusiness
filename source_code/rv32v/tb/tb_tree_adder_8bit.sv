`timescale 1ns/10ps
module tb_tree_adder_8bit ();
  logic [7:0] tb_add_in;
  logic [3:0] tb_add_out;

  tree_adder_8bit DUT (.add_in(tb_add_in), .add_out(tb_add_out));  

  task set_input;
    input logic [7:0] in;
    input logic [3:0] out;
  begin
    tb_add_in = in;
    #(1);
    assert(tb_add_out == out) $info("CORRECT OUTPUT");
    else $error("INCORRECT OUTPUT. ACTUAL: %d. EXPECTED: %d", tb_add_out, out);
    #(4);
  end
  endtask 

  initial begin
    #(5);
    set_input(8'b00000000, 0);
    set_input(8'b11111111, 8);
    set_input(8'b00000001, 1);
    set_input(8'b00000010, 1);
    set_input(8'b00000100, 1);
    set_input(8'b00001000, 1);
    set_input(8'b00010000, 1);
    set_input(8'b00100000, 1);
    set_input(8'b01000000, 1);
    set_input(8'b10000000, 1);
    set_input(8'b01010000, 2);
    set_input(8'b00110001, 3);
    set_input(8'b10010001, 3);
    set_input(8'b10101010, 4);
    set_input(8'b01010101, 4);
    set_input(8'b11110010, 5);
    set_input(8'b01010111, 5);
    set_input(8'b11110101, 6);
    set_input(8'b10111101, 6);
    set_input(8'b11111101, 7);
    set_input(8'b01111111, 7);
    $finish;
  end
	
endmodule
