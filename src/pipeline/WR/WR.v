module WR 
#(
    parameter               NB_REG  = 32
)(
    input [NB_REG-1:0]      i_alu_result    ,
    input [NB_REG-1:0]      i_data_from_mem ,  //ReadData
    input [NB_REG-1:0]      i_pcplus8       ,
    input                   i_MemToReg      ,
    input                   i_isJal         ,
    output [NB_REG-1:0]     o_data_to_reg   
);

wire [NB_REG-1:0] mpx1_to_mpx2;

mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_wr_mpx_1
(
    .i_a       (i_alu_result),   
    .i_b       (i_data_from_mem),   
    .i_sel     (i_MemToReg),  
    .o_out     (mpx1_to_mpx2)  
);

mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_wr_mpx_2
(
    .i_a       (mpx1_to_mpx2),   
    .i_b       (i_pcplus8),  
    .i_sel     (i_isJal),  
    .o_out     (o_data_to_reg)  
);
    
endmodule