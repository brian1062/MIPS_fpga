`timescale 1ns/1ps

/////////////////////////////////////////////////////////////
// Module: Forwarding Unit
// Description: Handles data hazards by determining if
//              forwarding is needed for source operands.
// Author: Emanuel Rodriguez
// Created: 21/11/2024
// Parameters:
//   - NB_REG: Bit-width of register identifiers (default: 5).
// Inputs:
//   - i_rd_from_ID: Source register 1 identifier from ID stage.
//   - i_rt_from_ID: Source register 2 identifier from ID stage.
//   - i_rd_from_M: Destination register identifier from EX/M stage.
//   - i_rd_from_WB: Destination register identifier from M/WB stage.
//   - i_RegWrite_from_M: RegWrite signal from EX/M stage.
//   - i_RegWrite_from_WB: RegWrite signal from M/WB stage.
// Outputs:
//   - o_forwardA: Forwarding control signal for source operand A.
//   - o_forwardB: Forwarding control signal for source operand B.
/////////////////////////////////////////////////////////////

module forwarding_unit_EX #(
    parameter NB_REG = 5 // Register identifier width
) (
    // Inputs
    input [NB_REG-1:0] i_rs_from_ID,       // Source register 1 from ID stage
    input [NB_REG-1:0] i_rt_from_ID,       // Source register 2 from ID stage
    input [NB_REG-1:0] i_rd_from_M,        // Destination register from EX/M stage
    input [NB_REG-1:0] i_rd_from_WB,       // Destination register from M/WB stage
    input              i_RegWrite_from_M, // RegWrite signal from EX/M stage
    input              i_RegWrite_from_WB,// RegWrite signal from M/WB stage

    // Outputs
    output  [1:0]   o_forwardA,         // Forwarding signal for operand A
    output  [1:0]   o_forwardB          // Forwarding signal for operand B
);

/////////////////////////////////////////////////////////////
// Forwarding Logic
/////////////////////////////////////////////////////////////
reg [1:0] forwardA;
reg [1:0] forwardB;

always @(*) begin

    // Forwarding for o_forwardA
    if (i_RegWrite_from_M && (i_rd_from_M != 0) && (i_rd_from_M == i_rs_from_ID)) 
    begin
        forwardA = 2'b10; // Forward from EX/M stage
    end 
    else if (i_RegWrite_from_WB && (i_rd_from_WB != 0) && (i_rd_from_WB == i_rs_from_ID)) 
    begin
        forwardA = 2'b01; // Forward from M/WB stage
    end
    else 
    begin
        forwardA = 2'b00;
    end

    // Forwarding for o_forwardB
    if (i_RegWrite_from_M && (i_rd_from_M != 0) && (i_rd_from_M == i_rt_from_ID)) 
    begin
        forwardB = 2'b10; // Forward from EX/M stage
    end 
    else if (i_RegWrite_from_WB && (i_rd_from_WB != 0) && (i_rd_from_WB == i_rt_from_ID)) 
    begin
        forwardB = 2'b01; // Forward from M/WB stage
    end
    else
    begin
        forwardB = 2'b00;
    end
end
assign o_forwardA = forwardA;
assign o_forwardB = forwardB;

endmodule
