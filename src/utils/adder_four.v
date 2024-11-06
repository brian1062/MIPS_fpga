`timescale 1ns / 1ps

module adder_four
#(
    parameter ADDER_WIDTH = 32 
)
(
    input  [ADDER_WIDTH-1:0] a_input  ,
    output [ADDER_WIDTH-1:0] sum
);

assign sum = a_input + 3'b100; //! add 4 to the input

endmodule



