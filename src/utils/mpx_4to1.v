`timescale 1ns / 1ps

module mpx_4to1 
#(
    parameter NB_INPUT = 32,            //! is the width of the input
    parameter NB_SEL   = 2
)
(
    input  [NB_INPUT-1:0] i_a       ,  //! is the input to be selected when i_sel is 00
    input  [NB_INPUT-1:0] i_b       ,  //! is the input to be selected when i_sel is 01
    input  [NB_INPUT-1:0] i_c       ,  //! is the input to be selected when i_sel is 10
    input  [NB_INPUT-1:0] i_d       ,  //! is the input to be selected when i_sel is 11
    input  [NB_SEL  -1:0] i_sel     ,  //! is the selector
    output [NB_INPUT-1:0] o_out        //! is the output
);

    reg [NB_INPUT-1:0] value;

    always @(i_sel, i_a, i_b, i_c, i_d)
    case (i_sel)
    2'b00: value = i_a;
    2'b01: value = i_b;
    2'b10: value = i_c;
    2'b11: value = i_d;
    default: value = i_a;
    endcase

    assign o_out = value;

endmodule