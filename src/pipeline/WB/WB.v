//===========================================
// Module: WB (Write Back)
// Description: 
//    The Write Back (WB) module selects the final 
//    data to be written back to the register file 
//    at the end of the pipeline. It handles data 
//    from the ALU, memory, and the PC+8 value 
//    (used for JAL instructions). The module uses 
//    two 2-to-1 multiplexers to choose the correct 
//    data based on control signals.
// Author: Brian Gerard
// Created: 12/11/2024
// Parameters:
// - NB_REG: Width of the registers and data buses 
//           (default: 32 bits)
// Inputs:
// - i_alu_result: Data from the ALU (ALU result)
// - i_data_from_mem: Data read from memory (ReadData)
// - i_pcplus8: PC+8 value used for JAL instructions
// - i_MemToReg: Control signal to select between ALU 
//               result and memory data
// - i_isJal: Control signal to select between 
//            PC+8 and the output of the first multiplexer
// Outputs:
// - o_data_to_reg: Final data to be written back to the 
//                  register file
//===========================================


module WB
#(
    parameter               NB_REG  = 32 // Default width of registers and data buses
)(
    input [NB_REG-1:0]      i_alu_result,      // ALU result
    input [NB_REG-1:0]      i_data_from_mem,   // Data from memory (ReadData)
    input [NB_REG-1:0]      i_pcplus8,         // PC+8 value (used for JAL)
    input                   i_MemToReg,        // MemToReg control signal
    input                   i_isJal,           // JAL control signal
    output [NB_REG-1:0]     o_data_to_reg      // Data to be written to register file
);

// Internal wire connecting the output of the first multiplexer to the input of the second
wire [NB_REG-1:0] mpx1_to_mpx2;

mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_wr_mpx_1
(
    .i_a       (i_alu_result),        // ALU result
    .i_b       (i_data_from_mem),     // Memory data
    .i_sel     (i_MemToReg),          // MemToReg control signal
    .o_out     (mpx1_to_mpx2)         // Output to the next multiplexer
);

// Second multiplexer: Selects between the output of the first multiplexer and PC+8
mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_wr_mpx_2
(
    .i_a       (mpx1_to_mpx2),        // Output from the first multiplexer
    .i_b       (i_pcplus8),           // PC+8 value
    .i_sel     (i_isJal),             // JAL control signal
    .o_out     (o_data_to_reg)        // Final output data to register file
);
    
endmodule