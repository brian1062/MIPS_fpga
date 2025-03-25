//===========================================
// Module: hazard_unit
// Description:
//    Detects data and control hazards in the pipeline processor.
//    Generates stall and flush signals to manage pipeline conflicts,
//    ensuring correct execution by handling dependencies and branch mispredictions.
// Author: Brian Gerard
// Created: 14/02/2025
// Parameters:
// - NB_ADDR: Bit width for register addresses (default: 5).
// Inputs:
// - i_branch: Indicates a branch instruction is being processed.
// - i_rs_id: Register source address from the ID stage [4:0].
// - i_rt_id: Register target address from the ID stage [4:0].
// - i_rt_ex: Register target address from the EX stage [4:0].
// - i_rd_ex: Destination register address from the EX stage [4:0].
// - i_rd_mem: Destination register address from the MEM stage [4:0].
// - i_mem_read_ex: Signal indicating a load operation in the EX stage (mem_read).
// - i_regwrite_ex: Signal indicating register writeback in the EX stage.
// - i_memtoreg_m: Signal indicating memory-to-register write in the MEM stage.
// Outputs:
// - o_flush_idex: Flush signal for ID/EX pipeline register.
// - o_stall: Stall signal to pause the pipeline stages.
//===========================================
module hazard_unit 
#(
    parameter NB_ADDR = 5 
)
(
    // input                i_jump       ,
    input                i_branch     ,

    input [NB_ADDR-1:0]  i_rs_id      ,
    input [NB_ADDR-1:0]  i_rt_id      ,
    input [NB_ADDR-1:0]  i_rt_ex      ,
    input [NB_ADDR-1:0]  i_rd_ex      ,
    input [NB_ADDR-1:0]  i_rd_mem     ,
    input                i_mem_read_ex, //load operations   |memread_e writereg_m  regwrite_E  memread_m
    input                i_regwrite_ex,  //writereg_e
    input                i_memtoreg_m , 

    output               o_flush_idex,
    output               o_stall
);


reg reg_flush;
reg reg_stall;
always @(*) begin
    //read load data hazard
    if((i_mem_read_ex) && ((i_rs_id == i_rt_ex) || (i_rt_id == i_rt_ex)))
    begin
        reg_flush = 1'b1;
        reg_stall = 1'b1;
    end

    else if(i_branch && (
        (i_regwrite_ex && (i_rd_ex != 5'b00000) &&
        ((i_rd_ex == i_rs_id)|| (i_rd_ex == i_rt_id)))
        ||
        (i_memtoreg_m && (i_rd_mem != 5'b00000) &&    
        ((i_rd_mem == i_rs_id) || (i_rd_mem == i_rt_id)))
    ))
        begin
            reg_flush = 1'b1;
            reg_stall = 1'b1;
        end
    else begin
        reg_flush = 1'b0;
        reg_stall = 1'b0;
    end
    
end

assign o_flush_idex = reg_flush;
assign o_stall      = reg_stall;

    
endmodule


