`timescale 1ns / 1ps

//===========================================
// Module: IF
// Description: Instruction Fetch (IF) module 
//              that handles the fetching of 
//              instructions from memory. 
//              Integrates program counter (PC), 
//              multiplexers, and an instruction 
//              memory to support jumps, branches, 
//              and PC+4 logic.
// Author: Brian Gerard
// Created: 11/11/2024
// Parameters:
// - NB_REG: Width of registers and PC (default: 32 bits)
// - NB_WIDHT: Address width for instruction memory (default: 9 bits)
// - NB_INST: Instruction width for jump address concatenation (default: 26 bits)
// Inputs:
// - i_clk: Clock signal (active on positive edge)
// - i_reset: Asynchronous reset (active high)
// - i_dunit_clk_en: Enable signal for clock gating in data unit
// - i_dunit_w_en: Write enable signal for the data unit
// - i_dunit_addr: Address input for the data unit
// - i_PCSrc: Selector for PC source (0: PC+4, 1: Immediate)
// - i_Jump: Control signal for jump operations
// - i_JSel: Selector for jump address sources
// - i_PCWrite: Write enable signal for the program counter
// - i_inmed: Immediate value for jump/branch
// - i_inst_to_mxp: Instruction bits for jump address concatenation
// - i_pc_jsel: PC value for jump select operations
// - i_dunit_data: Data input for writing into instruction memory
// Outputs:
// - o_pcplus4: Calculated PC+4 value for next instruction
// - o_instruction: Fetched instruction from instruction memory
//===========================================

module IF
#(
    parameter               NB_REG  = 32,  // Width of registers and PC
    parameter               NB_WIDHT = 9,  // Address width for instruction memory
    parameter               NB_INST = 26   // Instruction width for concatenation
)
(
    input                   i_clk,          // Clock signal
    input                   i_reset,        // Reset signal
    input                   i_dunit_clk_en, // Clock enable signal for data unit
    input                   i_dunit_w_en,   // Write enable signal for data unit
    input  [NB_REG-1:0]   i_dunit_addr,   // Address input for data unit
    input                   i_PCSrc,        // Selector for PC source
    input                   i_Jump,         // Jump signal
    input                   i_JSel,         // Selector for jump address
    input                   i_PCWrite,      // Write enable for PC
    input  [NB_REG-1:0]     i_inmed,        // Immediate value for jump/branch
    input  [NB_INST-1:0]    i_inst_to_mxp,  // Instruction bits for concatenation
    input  [NB_REG-1:0]     i_pc_jsel,      // PC value for jump select
    input  [NB_REG-1:0]     i_dunit_data,   // Data for instruction memory write
    output [NB_REG-1:0]     o_pcplus4,      // Calculated PC+4
    output [NB_REG-1:0]     o_instruction   // Instruction fetched from memory
);

// Internal wire for PC and multiplexers
wire [NB_REG-1:0] pc_to_mem;        // Current PC value for memory
wire [NB_REG-1:0] mpx3_to_pc;       // Output of third multiplexer to PC
wire [NB_REG-1:0] mpx2_to_mpx3;     // Output of second multiplexer
wire [NB_REG-1:0] mpx1_to_mpx2;     // Output of first multiplexer
wire [NB_REG-1:0] instr_addr;


// First multiplexer: Selects between PC+4 and immediate value
mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_mpx_1
(  
    .i_a       (o_pcplus4),       // PC+4
    .i_b       (i_inmed),         // Immediate value
    .i_sel     (i_PCSrc),         // Selector signal
    .o_out     (mpx1_to_mpx2)     // Output to next multiplexer
);

// Second multiplexer: Concatenates PC+4 with instruction bits for jump address
mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_mpx_2 (
    .i_a       (mpx1_to_mpx2),    // Output from previous multiplexer
    .i_b       ({o_pcplus4[31:28], i_inst_to_mxp, 2'b00}), // Concatenated jump address
    .i_sel     (i_Jump),          // Selector signal
    .o_out     (mpx2_to_mpx3)     // Output to next multiplexer
);

mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_mpx_3
(
    .i_a       (mpx2_to_mpx3),   
    .i_b       (i_pc_jsel   ),   
    .i_sel     (i_JSel      ),  
    .o_out     (mpx3_to_pc  )  
);

// Program counter (PC) module
pc #(
    .PC_WIDTH(NB_REG)
) u_pc (
    .i_clk      (i_clk              ),
    .i_reset    (i_reset            ),
    .i_enable   (i_dunit_clk_en     ),
    .PCWrite    (i_PCWrite          ),
    .pc_in      (mpx3_to_pc         ),
    .pc_out     (pc_to_mem          )
);

// Adder for calculating PC+4
adder_four #(
    .ADDER_WIDTH(NB_REG) 
) u_adder_four (
    .a_input     (pc_to_mem         ),
    .sum         (o_pcplus4         )
);

// Instruction memory (asynchronous RAM)
ram_async_single_port #(
      .NB_WIDHT  (NB_REG   ), // Memory width
      .NB_ADDR   (NB_WIDHT ), // Address width 512 posiciones
      .NB_DATA   (8        )  // Data width 8 bits de ancho
) u_instruction_memory (
      .i_clk       (i_clk       ),
      .i_reset     (i_reset     ),
      .i_we        (i_dunit_w_en),
      .i_addr      (instr_addr[NB_WIDHT-1:0] ),
      .i_data_in   (i_dunit_data),
      .o_data_out  (o_instruction)
  );

assign instr_addr = i_dunit_w_en ? i_dunit_addr : pc_to_mem;
    
endmodule