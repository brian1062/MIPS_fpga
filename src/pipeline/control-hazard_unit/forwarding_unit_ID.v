//===========================================
// Module: forwarding_unit_ID
// Description: 
//    Forwarding Unit for the ID stage of a pipeline.
//    Detects data hazards by comparing the source 
//    registers (rs and rt) from the ID stage with the 
//    destination register (rd) of the EX/MEM stage. 
//    Generates control signals to forward data from 
//    the EX/MEM pipeline stage when necessary.
// Author: Brian Gerard
// Created: 17/11/2024
// Parameters:
// - NB_ADDR: Bit width for register addresses 
//            (default: 5 bits for a 32-register file)
// Inputs:
// - i_rs_id: Address of the rs register in the ID stage
// - i_rt_id: Address of the rt register in the ID stage
// - i_rd_ex_m: Address of the destination register in 
//              the EX/MEM stage
// - i_regWrite_ex_m: Write enable signal for the EX/MEM 
//                    stage, indicating if the destination 
//                    register will be written
// Outputs:
// - o_forwardA_ID: Forwarding control signal for rs in 
//                  the ID stage
// - o_forwardB_ID: Forwarding control signal for rt in 
//                  the ID stage
//===========================================


module forwarding_unit_ID 
#(
    parameter NB_ADDR  = 5 // Default width for register addresses
) 
(
    input [NB_ADDR-1:0]     i_rs_id,          // rs address in ID stage
    input [NB_ADDR-1:0]     i_rt_id,          // rt address in ID stage
    input [NB_ADDR-1:0]     i_rd_ex_m,        // Destination register address in EX/MEM stage
    input                   i_regWrite_ex_m,  // Write enable signal from EX/MEM stage

    output  reg                o_forwardA_ID,    // Forwarding control for rs in ID stage
    output  reg                o_forwardB_ID     // Forwarding control for rt in ID stage
);

// Forwarding logic for rs register
// assign o_forwardA_ID = (i_rs_id == i_rd_ex_m) && i_regWrite_ex_m;

// // Forwarding logic for rt register
// assign o_forwardB_ID = (i_rt_id == i_rd_ex_m) && i_regWrite_ex_m;

always @(*) 
begin
    if ((i_rs_id == i_rd_ex_m)&& i_regWrite_ex_m) begin
        o_forwardA_ID = 1'b1;
    end
    else begin
        o_forwardA_ID = 1'b0;
    end
    if ((i_rt_id == i_rd_ex_m) && i_regWrite_ex_m) begin
        o_forwardB_ID = 1'b1;
    end
    else begin
        o_forwardB_ID = 1'b0;
    end
end

endmodule