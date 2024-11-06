`timescale 1ns / 1ps

module mpx_2to1 
#(
    parameter NB_INPUT = 32            //! is the width of the input
)
(
    input  [NB_INPUT-1:0] i_a       ,  //! is the input to be selected when i_sel is 0
    input  [NB_INPUT-1:0] i_b       ,  //! is the input to be selected when i_sel is 1
    input                 i_sel     ,  //! is the selector
    output [NB_INPUT-1:0] o_out        //! is the output
);

assign o_out = i_sel ? i_b : i_a;      //! if i_sel is 1, then o_out is i_b, otherwise o_out is i_a
    
endmodule