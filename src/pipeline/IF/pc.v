//===========================================
// Module: pc
// Description: Program Counter module that 
//              maintains the current program
//              counter (PC) value. Supports 
//              reset, enable, and write controls.
// Author: Brian Gerard
// Created: 13/11/2024
// Parameters:
// - PC_WIDTH: Width of the program counter (default: 32 bits)
// Inputs:
// - i_clk: Clock signal (active on positive edge)
// - i_reset: Asynchronous reset (active high)
// - i_enable: Global enable signal
// - PCWrite: Write enable signal for PC update
// - pc_in: Input value for the program counter
// Outputs:
// - pc_out: Current value of the program counter
//===========================================

module pc 
#(
    parameter PC_WIDTH = 32 // Default width of the PC register
)
(
    input       i_clk,                // Clock signal
    input       i_reset,              // Asynchronous reset
    input       i_enable,             // Global enable signal
    input       PCWrite,              // Write enable for PC
    input       [PC_WIDTH-1:0] pc_in, // Input value for the PC
    output      [PC_WIDTH-1:0] pc_out // Output current PC value
);

    reg [PC_WIDTH-1:0] pc;


    always @(posedge i_clk )
    begin
        if (i_reset)
            pc <= 32'b0;
        else if (i_enable & PCWrite)
            pc <= pc_in;
        else
            pc <= pc;
    end


    assign pc_out = pc;

    
endmodule