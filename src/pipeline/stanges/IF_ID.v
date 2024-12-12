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
    input                   i_flush,   // en 1 flush = reset register
    input                   i_write,   // EN 0 STALL mantengo valor anteriores esto debo conectarlo al pc tmb

    output    [NB_REG-1:0]  o_pc_four,
    output    [NB_REG-1:0]  o_data_ins_mem

);

reg [NB_REG-1:0] pc_reg;
reg [NB_REG-1:0] inst_mem_reg;

always @(posedge i_clk) begin
    if (i_reset || i_flush) begin
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
