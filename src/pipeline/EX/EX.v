`timescale 1ns/1ps

/////////////////////////////////////////////////////////////
// Module: EX
// Description: Execution stage module for a pipelined processor.
//              Handles ALU operations, forwarding logic, and 
//              register destination selection.
// Author: Emanuel Rodriguez
// Created: 18/11/2024
// Parameters:
//   - NB_REG: Bit-width of the registers (default: 32).
//   - NB_ADDR: Bit-width of the register addresses (default: 5).
//   - ALU_OP: Bit-width of the ALU operation control signal.
// Inputs:
//   - i_alu_src_CU: ALU source control signal.
//   - i_reg_dst_CU: Register destination control signal.
//   - i_jal_sel_CU: JAL destination control signal.
//   - i_alu_op_CU: ALU operation control signal.
//   - i_rs_data, i_rt_data: Operand data for RS and RT.
//   - i_rd_from_ID, i_rt_from_ID: RD and RT addresses from ID stage.
//   - i_inst_sign_extended: Sign-extended immediate value.
//   - i_aluResult_WB, i_aluResult_MEM: Forwarded ALU results.
//   - i_op_r_tipe: Decoded operation type.
//   - i_forwardA, i_forwardB: Forwarding control signals.
// Outputs:
//   - o_alu_result: ALU operation result.
//   - o_write_reg: Destination register address.
//   - o_rd_to_WB: RD data for WB stage.
//   - o_alu_condition_zero: ALU condition zero flag.
/////////////////////////////////////////////////////////////

module EX #(
    parameter NB_REG  = 32,    // Register and data width
    parameter NB_ADDR = 5 ,    // Register address width
    parameter NB_OP   = 6 ,
    parameter ALU_OP  = 4      // ALU operation width
) (  
    // Control signals
    input                       i_alu_src_CU        , // Control signal for ALU source
    input                       i_reg_dst_CU        , // Control signal for register destination
    input                       i_jal_sel_CU        , // Control signal for JAL
    input        [ALU_OP-1 : 0] i_alu_op_CU         , // ALU operation control

    // Data inputs
    input        [NB_REG-1:0]   i_rs_data           , // Operand RS data
    input        [NB_REG-1:0]   i_rt_data           , // Operand RT data
    input        [NB_ADDR-1:0]  i_rd_from_ID        , // RD address from ID stage
    input        [NB_ADDR-1:0]  i_rt_from_ID        , // RT address from ID stage
    input signed [NB_REG-1:0]   i_inst_sign_extended, // Sign-extended immediate
    input        [NB_REG-1:0]   i_aluResult_WB      , // Forwarded ALU result from WB
    input        [NB_REG-1:0]   i_aluResult_MEM     , // Forwarded ALU result from MEM
    input        [NB_OP -1:0]   i_op_r_tipe         , // Decoded operation type

    // Forwarding control
    input        [1:0]          i_forwardA          , // Forwarding control for A
    input        [1:0]          i_forwardB          , // Forwarding control for B

    // Outputs
    output       [NB_REG-1:0]   o_alu_result        , // ALU operation result
    output       [NB_REG-1:0]   o_write_reg         , // Destination register address
    output       [NB_ADDR-1:0]  o_rd_to_WB           // RD data for WB
);

/////////////////////////////////////////////////////////////
// Internal Signals
/////////////////////////////////////////////////////////////
wire [NB_REG-1:0] alu_input_A;
wire [NB_REG-1:0] alu_input_B;
wire [NB_REG-1:0] alu_mux3_out;
wire [NB_ADDR-1:0] rd_mux1_out;
wire [NB_OP-1:0] alu_control_signals;

/////////////////////////////////////////////////////////////
// Forwarding Multiplexers for ALU Inputs
/////////////////////////////////////////////////////////////
mpx_4to1 #(
    .NB_INPUT(NB_REG)
) u_mux_forwardA (
    .i_a   (i_rs_data       ),
    .i_b   (i_aluResult_WB  ),
    .i_c   (i_aluResult_MEM ),
    .i_d   (32'b0           ), // Unused input
    .i_sel (i_forwardA      ),
    .o_out (alu_input_A     )
);

mpx_4to1 #(
    .NB_INPUT(NB_REG)
) u_mux_forwardB (
    .i_a   (i_rt_data       ),
    .i_b   (i_aluResult_WB  ),
    .i_c   (i_aluResult_MEM ),
    .i_d   (32'b0           ), // Unused input
    .i_sel (i_forwardB      ),
    .o_out (alu_mux3_out    )
);

assign o_write_reg = alu_mux3_out; //Bifurcation of the output of the second multiplexer

mpx_2to1 #(
    .NB_INPUT(NB_REG)
) u_mux_alu_src (
    .i_a   (alu_mux3_out        ),
    .i_b   (i_inst_sign_extended),
    .i_sel (i_alu_src_CU        ),
    .o_out (alu_input_B)
);

/////////////////////////////////////////////////////////////
// ALU Control and ALU Modules
/////////////////////////////////////////////////////////////
ALU_Control u_alu_control (
    .i_op_r_tipe           (i_op_r_tipe          ),// Passing the least significant 6 bits of i_op_r_tipe to ALU_Control
    .i_alu_op_CU           (i_alu_op_CU          ),
    .o_alu_control_signals (alu_control_signals  )
);

ALU #(
    .NB_INPUT (NB_REG),
    .NB_CONTROL(NB_OP)
) u_alu (
    .alu_input_A           (alu_input_A          ),
    .alu_input_B           (alu_input_B          ),
    .i_alu_control_signals (alu_control_signals  ),
    .i_shamt               (i_inst_sign_extended[10:6]),
    .o_alu_result          (o_alu_result         )
);

/////////////////////////////////////////////////////////////
// Multiplexers for Register Destination Selection
/////////////////////////////////////////////////////////////
mpx_2to1 #(
    .NB_INPUT(NB_ADDR)
) u_mux_rd1 (
    .i_a   (i_rd_from_ID  ),
    .i_b   (i_rt_from_ID  ),
    .i_sel (i_reg_dst_CU  ),
    .o_out (rd_mux1_out   )
);

mpx_2to1 #(
    .NB_INPUT(NB_ADDR)
) u_mux_rd2 (
    .i_a   (rd_mux1_out   ),
    .i_b   (5'h1F         ), // JAL destination register ($ra)
    .i_sel (i_jal_sel_CU  ),
    .o_out (o_rd_to_WB   )
);

endmodule
