`timescale 1ns/1ps

/////////////////////////////////////////////////////////////
// Module: ID
// Description: Instruction Decode module for a pipelined processor.
//              Handles instruction decoding, forwarding, 
//              branch decision logic, and PC updates.
// Author: Brian Gerard
// Created: 13/11/2024
// Parameters:
//   - NB_REG: Bit-width of the registers (default: 32).
//   - NB_ADDR: Bit-width of the register addresses (default: 5).
// Inputs:
//   - i_clk, i_reset: Clock and reset signals.
//   - i_dunit_clk_en: Clock enable signal for the debug unit.
//   - i_regWrite_from_WB: Write enable signal from WB stage.
//   - i_forwardA, i_forwardB: Forwarding control signals for operands.
//   - i_inst_from_IF: Instruction from IF stage.
//   - i_pcplus4: PC + 4 from IF stage.
//   - i_WB_addr, i_WB_data: Write-back address and data.
//   - i_aluResult: ALU result for forwarding.
//   - i_isBeq, i_branch: Signals indicating branch type and validity.
// Outputs:
//   - o_pc_jsel_to_IF: PC value for branch or jump.
//   - o_PCSrc_to_IF: Select signal for PC source.
//   - o_branch_target: Calculated branch target address.
//   - o_pcplus8: PC + 8 (used for jumps).
//   - o_inst_sign_extended: Sign-extended immediate value.
//   - o_rs_data, o_rt_data: Operand data for RS and RT.
//   - o_op_r_tipe, o_rs_addr, o_rt_addr, o_rd_addr: Decoded instruction fields.
/////////////////////////////////////////////////////////////


module ID #(
    parameter NB_REG  = 32,
    parameter NB_ADDR =  5
) (
    input                      i_clk               , // Clock signal.
    input                      i_reset             , // Reset signal.
    input                      i_dunit_clk_en      , // Data unit clock enable.
    input                      i_regWrite_from_WB  , // Write enable from WB stage.
    input                      i_forwardA          , // Forwarding control for operand A.
    input                      i_forwardB          , // Forwarding control for operand B.
    
    // ->#
    input         [NB_REG-1:0] i_inst_from_IF      , // Instruction from IF stage.
    input         [NB_REG-1:0] i_pcplus4           , // PC + 4 from IF stage.
   
    //  #
    //  ^
    input         [NB_ADDR-1:0]i_WB_addr           , // Write-back register address.
    input         [NB_REG-1:0] i_WB_data           , // Write-back data.
    input         [NB_REG-1:0] i_aluResult         , // ALU result for forwarding.
    input                      i_isBeq             , // BEQ indicator signal.
    input                      i_branch            , // Branch signal.

    input         [NB_ADDR-1:0]i_dunit_addr        ,
    output        [NB_REG -1:0]o_dunit_reg         ,
    
    // <-#
    output reg       [NB_REG-1:0] o_pc_jsel_to_IF     , // PC value for jump/branch.
    output reg                    o_PCSrc_to_IF       , // Select signal for PC source.
    output reg       [NB_REG-1:0] o_branch_target     , // Calculated branch target address.

    // #->
    output        [NB_REG-1:0] o_pcplus8           , // PC + 8 (used in some jumps).
    output        [NB_REG-1:0] o_inst_sign_extended, // Sign-extended immediate value. TODO:VER SI VA SIGNED ACA O NO
    output        [NB_REG-1:0] o_rs_data           , // Operand data for RS.
    output        [6-1:0]o_op_r_tipe         , // Opcode or instruction type.
    output reg       [NB_ADDR-1:0]o_rs_addr           , // RS register address.
    output reg       [NB_ADDR-1:0]o_rt_addr           , // RT register address.
    output reg       [NB_ADDR-1:0]o_rd_addr           , // RD register address.
    output        [NB_REG-1:0] o_rt_data           // Operand data for RT.
);
wire [NB_REG-1:0] o_alu_rs_data;
wire [NB_REG-1:0] o_alu_rt_data;

/////////////////////////////////////////////////////////////
// Sign Extension
// Extends the 16-bit immediate value from the instruction to 32 bits.
/////////////////////////////////////////////////////////////
sign_extend #(
    .NB_IN  (16),
    .NB_OUT (32)
) u_sign_extend (
    .i_data(i_inst_from_IF[15:0]),  // Lower 16 bits of the instruction.
    .o_data(o_inst_sign_extended)  // 32-bit sign-extended output.
);

/////////////////////////////////////////////////////////////
// Register File
// Reads and writes register data.
/////////////////////////////////////////////////////////////
register_mem #(
    .NB_REG  (NB_REG  ),
    .NB_ADDR (NB_ADDR )
) u_register_mem (
    .i_clk          (i_clk                ),
    .i_reset        (i_reset              ),   //clean all registers
    .i_enable       (i_regWrite_from_WB   ),
    .i_dunit_clk_en (i_dunit_clk_en       ),
    .i_rs_addr      (i_inst_from_IF[25:21]),
    .i_rt_addr      (i_inst_from_IF[20:16]),
    .i_wb_addr      (i_WB_addr            ),   //from wb
    .i_wb_data      (i_WB_data            ),   //from wb
    .i_dunit_addr   (i_dunit_addr         ),
    .o_dunit_reg    (o_dunit_reg          ),
    .o_rs_data      (o_alu_rs_data        ),
    .o_rt_data      (o_alu_rt_data        )
);
// assign o_pc_jsel_to_IF = o_alu_rs_data;  //conect input2 mux_3 en IF


/////////////////////////////////////////////////////////////
// Forwarding Logic
// Determines whether to use forwarded data or register data.
/////////////////////////////////////////////////////////////
mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) id_mpx_1
(
    .i_a       (o_alu_rs_data),   
    .i_b       (i_aluResult  ),   
    .i_sel     (i_forwardA   ),  
    .o_out     (o_rs_data    )  
);

mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) id_mpx_2
(
    .i_a       (o_alu_rt_data),   
    .i_b       (i_aluResult  ),  
    .i_sel     (i_forwardB   ),  
    .o_out     (o_rt_data    )  
);

/////////////////////////////////////////////////////////////
// Branch Decision Logic
// Compares RS and RT values and determines if a branch should occur.
/////////////////////////////////////////////////////////////
wire rs_equals_rt;               // Comparación entre o_rs_data y o_rt_data
assign rs_equals_rt = | (o_rs_data ^ o_rt_data);

wire wire_to_and;                // Selección según IsBeq
mpx_2to1 #(
    .NB_INPUT(1)          
) u_mpx_beq_bne
(
    .i_a       (rs_equals_rt),   
    .i_b       (~rs_equals_rt),   
    .i_sel     (i_isBeq),  
    .o_out     (wire_to_and  )  
);
// assign o_PCSrc_to_IF = i_branch & wire_to_and;



/////////////////////////////////////////////////////////////
// Branch Target Calculation
// Computes the target address for branch instructions.
/////////////////////////////////////////////////////////////
// assign o_branch_target = i_pcplus4 + (extended_inst << 2); // se concatena el pc+4 con la instrucción mas su desplazamiento

/////////////////////////////////////////////////////////////
// Additional Outputs
// Provides decoded fields and PC+8 for later stages.
/////////////////////////////////////////////////////////////
assign o_op_r_tipe  = i_inst_from_IF[5:0];
// assign o_rs_addr    = i_inst_from_IF[25:21];
// assign o_rt_addr    = i_inst_from_IF[20:16];
// assign o_rd_addr    = i_inst_from_IF[15:11];

assign o_pcplus8 = i_pcplus4 + 32'h00000004;

//do this to fix problem loop
always @(*) 
begin
    if(i_reset) begin
        o_pc_jsel_to_IF= 0;
        o_PCSrc_to_IF  = 0;
        o_branch_target= 0;
        o_rs_addr      = 0;
        o_rt_addr      = 0;
        o_rd_addr      = 0;
    end

    if(i_dunit_clk_en)begin
        o_pc_jsel_to_IF = o_alu_rs_data;
        o_PCSrc_to_IF   = i_branch & wire_to_and;

        o_branch_target = i_pcplus4 + (o_inst_sign_extended << 2);
        o_rs_addr       = i_inst_from_IF[25:21];
        o_rt_addr       = i_inst_from_IF[20:16];
        o_rd_addr       = i_inst_from_IF[15:11];

    end

end


endmodule