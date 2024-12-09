`timescale 1ns/1ps

/////////////////////////////////////////////////////////////
// Module: ALU
// Description: Performs arithmetic and logical operations
//              based on the control signals from ALU_Control.
// Author: Emanuel Rodriguez
// Created: 21/11/2024
// Parameters:
//   - NB_INPUT: Bit-width for the inputs (default: 32).
//   - NB_CONTROL: Bit-width for the control signals (default: 6).
// Inputs:
//   - alu_input_A: First operand for the ALU operation.
//   - alu_input_B: Second operand for the ALU operation.
//   - o_alu_control_signals: ALU operation control signal from ALU_Control.
// Outputs:
//   - o_alu_result: The result of the ALU operation.
//   - o_alu_condition_zero: Flag that indicates if the result is zero (1 if zero, 0 otherwise).
/////////////////////////////////////////////////////////////

module ALU #(
    parameter NB_INPUT = 32,  // Bit-width for the inputs and outputs (default: 32)
    parameter NB_CONTROL = 6  // Bit-width for the ALU control signals
) (
    // Inputs
    input      [NB_INPUT-1:0] alu_input_A,             // First operand
    input      [NB_INPUT-1:0] alu_input_B,             // Second operand
    input      [NB_CONTROL-1:0] o_alu_control_signals, // ALU control signals

    // Outputs
    output reg [NB_INPUT-1:0] o_alu_result,        // ALU result
    output reg               o_alu_condition_zero  // Zero condition flag
);

/////////////////////////////////////////////////////////////
// ALU Operation Logic
/////////////////////////////////////////////////////////////

always @(*) begin
    case (o_alu_control_signals)
        6'b100000: o_alu_result = $signed(alu_input_A) + $signed(alu_input_B);  // ADD
        6'b100001: o_alu_result = alu_input_A + alu_input_B;  // ADDU (unsigned add)
        6'b100010: o_alu_result = $signed(alu_input_A) - $signed(alu_input_B);  // SUB
        6'b100011: o_alu_result = alu_input_A - alu_input_B;  // SUBU (unsigned subtract)
        6'b100100: o_alu_result = alu_input_A & alu_input_B;  // AND
        6'b100101: o_alu_result = alu_input_A | alu_input_B;  // OR
        6'b100110: o_alu_result = alu_input_A ^ alu_input_B;  // XOR
        6'b100111: o_alu_result = ~(alu_input_A | alu_input_B); // NOR
        6'b000000: o_alu_result = $unsigned(alu_input_B) << alu_input_A[4:0]; // SLL (Shift Left Logical)
        6'b000010: o_alu_result = $unsigned(alu_input_B) >> alu_input_A[4:0]; // SRL (Shift Right Logical)
        6'b000011: o_alu_result = $signed(alu_input_B) >>> alu_input_A[4:0]; // SRA (Shift Right Arithmetic)
        6'b101010: o_alu_result = ($signed(alu_input_A) < $signed(alu_input_B)) ? 1 : 0; // SLT (Set Less Than)
        6'b101011: o_alu_result = (alu_input_A < alu_input_B) ? 1 : 0; // SLTU (Set Less Than Unsigned)
        default: o_alu_result = 0; // Default case (should never occur)
    endcase

    // Check if the result is zero
    o_alu_condition_zero = (o_alu_result == 0) ? 1 : 0;
end

endmodule
