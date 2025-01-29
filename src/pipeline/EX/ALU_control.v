`timescale 1ns/1ps

/////////////////////////////////////////////////////////////
// Module: ALU Control
// Description: Determines the ALU operation based on the 
//              ALUOp signal from the control unit and 
//              function code for R-type instructions.
// Author: Emanuel Rodriguez
// Created: 20/11/2024
// Parameters:
//   - NB_FUNCT: Bit-width of the function code for R-type instructions (default: 6).
//   - NB_ALU_OP: Bit-width of the ALUOp signal (default: 4).
// Inputs:
//   - i_op_r_tipe: Function code for R-type instructions.
//   - i_alu_op_CU: ALUOp signal from control unit.
// Outputs:
//   - o_alu_control_signals: ALU control signal for the ALU module.
/////////////////////////////////////////////////////////////

module ALU_Control #(
    parameter NB_FUNCT = 6,   // Function field width for R-type instructions
    parameter NB_ALU_OP = 4   // ALUOp field width
) (
    // Inputs
    input      [NB_FUNCT-1:0]  i_op_r_tipe, // Function code for R-type instructions
    input      [NB_ALU_OP-1:0] i_alu_op_CU, // ALUOp signal from control unit

    // Outputs
    output reg [NB_FUNCT-1:0] o_alu_control_signals  // ALU control signal for ALU module
);

/////////////////////////////////////////////////////////////
// Local Parameters
/////////////////////////////////////////////////////////////

// Function codes for R-type instructions
localparam ADD  = 6'b100000; // Add Word
localparam ADDU = 6'b100001; // Add Unsigned Word
localparam SUB  = 6'b100010; // Subtract Word
localparam SUBU = 6'b100011; // Subtract Unsigned Word
localparam AND  = 6'b100100; // Logical AND
localparam OR   = 6'b100101; // Logical OR
localparam XOR  = 6'b100110; // Logical XOR
localparam NOR  = 6'b100111; // Logical NOR
localparam SLL  = 6'b000000; // Shift Word Left Logical
localparam SLLV = 6'b000100; // Shift Word Left Logical Variable
localparam SRL  = 6'b000010; // Shift Word Right Logical
localparam SRLV = 6'b000110; // Shift Word Right Logical Variable
localparam SRA  = 6'b000011; // Shift Word Right Arithmetic
localparam SRAV = 6'b000111; // Shift Word Right Arithmetic Variable
localparam SLT  = 6'b101010; // Set Less Than
localparam SLTU = 6'b101011; // Set Less Than Unsigned
localparam LUI  = 6'b001111; // Load Upper Immediate

// ALUOp values from control unit
localparam R_TYPE       = 4'b0010; // R-type instruction
localparam LOAD_STORE   = 4'b0000; // Load/Store operation
localparam I_TYPE_ADDIU  = 4'b0001; // ADDIU instruction
localparam I_TYPE_ANDI  = 4'b0100; // ANDI instruction
localparam I_TYPE_ORI   = 4'b0101; // ORI instruction
localparam I_TYPE_XORI  = 4'b1000; // XORI instruction
localparam I_TYPE_LUI   = 4'b1001; // LUI instruction
localparam I_TYPE_SLTI  = 4'b1100; // SLTI instruction
localparam I_TYPE_SLTIU = 4'b1101; // SLTIU instruction
localparam BRANCH       = 4'b0111; // Branch instructions (e.g., BEQ, BNE)

/////////////////////////////////////////////////////////////
// ALU Operation Selection Logic
/////////////////////////////////////////////////////////////

always @(*) begin
    case (i_alu_op_CU)
        R_TYPE: begin
            // Directly pass the function code for R-type instructions
            o_alu_control_signals = i_op_r_tipe; 
        end
        LOAD_STORE: begin
            // Load/Store operations perform addition
            o_alu_control_signals = ADD;
        end
        I_TYPE_ADDIU: begin
            // Immediate addition
            o_alu_control_signals = ADDU;
        end
        I_TYPE_ANDI: begin
            // AND immediate
            o_alu_control_signals = AND;
        end
        I_TYPE_ORI: begin
            // OR immediate
            o_alu_control_signals = OR;
        end
        I_TYPE_XORI: begin
            // XOR immediate
            o_alu_control_signals = XOR;
        end
        I_TYPE_LUI: begin
            // Load upper immediate
            o_alu_control_signals = LUI;
        end
        I_TYPE_SLTI: begin
            // Set less than immediate
            o_alu_control_signals = SLT;
        end
        I_TYPE_SLTIU: begin
            // Set less than immediate unsigned
            o_alu_control_signals = SLTU;
        end
        BRANCH: begin
            // Branch operations typically use subtraction for comparison
            o_alu_control_signals = SUB;
        end
        default: begin
            // Default to addition if no match
            o_alu_control_signals = ADD;
        end
    endcase
end

endmodule
