//===========================================
// Module: IF_ID
// Description:
//    Pipeline register between Instruction Fetch (IF) and Instruction Decode (ID) stages.
//    Stores the PC+4 value and fetched instruction.
//    Maintains pipeline synchronization by controlling data flow between stages.
// Author: Brian Gerard
// Created: 11/12/2024
// Parameters:
// - NB_REG: Bit width for registers and instruction data (default: 32).
// Inputs:
// - i_clk: System clock signal.
// - i_reset: Synchronous reset signal (flushes registers).
// - i_dunit_clk_en: Debug unit clock enable for controlled updates.
// - i_pc_four: PC+4 value from IF stage [31:0].
// - i_data_ins_mem: Fetched instruction from instruction memory [31:0].
// - i_write: Pipeline write enable (0 = stall, maintains current values).
// Outputs:
// - o_pc_four: Registered PC+4 output to ID stage [31:0].
// - o_data_ins_mem: Registered instruction output to ID stage [31:0].
//===========================================
module IF_ID 
#(
    parameter NB_REG = 32
) 
(
    input                   i_clk,
    input                   i_reset,
    input                   i_dunit_clk_en,
    input     [NB_REG-1:0]  i_pc_four,
    input     [NB_REG-1:0]  i_data_ins_mem,
    // input                   i_flush,   // en 1 flush = reset register
    input                   i_write,   // EN 0 STALL mantengo valor anteriores esto debo conectarlo al pc tmb

    output    [NB_REG-1:0]  o_pc_four,
    output    [NB_REG-1:0]  o_data_ins_mem

);

reg [NB_REG-1:0] pc_reg;
reg [NB_REG-1:0] inst_mem_reg;

always @(posedge i_clk) begin
    if (i_reset )begin//|| i_flush) begin
        pc_reg <= 32'b0;
        inst_mem_reg <= 32'b0;
    end
    else if (i_dunit_clk_en & i_write) begin
        pc_reg <= i_pc_four;
        inst_mem_reg <= i_data_ins_mem;
        
    end
    else begin
        pc_reg <= pc_reg;
        inst_mem_reg <= inst_mem_reg;
    end
    
end


assign  o_pc_four     = pc_reg;
assign  o_data_ins_mem = inst_mem_reg;
    
endmodule
