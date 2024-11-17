`timescale 1ns/1ps

/////////////////////////////////////////////////////////////
// Module: sign_extend
// Description: Sign-extension unit for extending smaller-width
//              signed values to a larger bit-width. Commonly used
//              in processors for immediate values or addressing.
// Author: Brian Gerard
// Created: 13/11/2024
// Parameters:
//   - NB_IN: Bit-width of the input data (default: 16).
//   - NB_OUT: Bit-width of the output data (default: 32).
// Inputs:
//   - i_data: Input value to be sign-extended.
// Outputs:
//   - o_data: Sign-extended output value.
/////////////////////////////////////////////////////////////

module sign_extend #(
    parameter NB_IN =  16,
    parameter NB_OUT = 32
) (
    input  [NB_IN -1:0] i_data,
    output [NB_OUT-1:0] o_data
);
/////////////////////////////////////////////////////////////
// Sign Extension Logic
// Replicates the most significant bit (MSB) of the input data
// to fill the additional bits required in the output.
/////////////////////////////////////////////////////////////
assign o_data = {{16{i_data[15]}}, i_data}; //o_data = {{16{i_data[15]}}, i_data};
    
endmodule