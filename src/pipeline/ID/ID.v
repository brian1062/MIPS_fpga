`timescale 1ns/1ps

module ID #(
    parameter NB_REG  = 32,
    parameter NB_ADDR =  5
) (
    input                      i_clk               ,
    input                      i_reset             ,
    input                      i_dunit_clk_en      ,
    input                      i_regWrite_from_WB  ,
    input                      i_forwardA          ,
    input                      i_forwardB          ,
    
    // ->#
    input         [NB_REG-1:0] i_inst_from_IF      ,
    input         [NB_REG-1:0] i_pcplus4           ,
    
    //  #
    //  ^
    input         [NB_ADDR-1:0]i_WB_addr           , //ADDR FROM WRITE BACK
    input         [NB_REG-1:0] i_WB_data           , //DATA FROM WRITE BACK
    input         [NB_REG-1:0] i_aluResult         , //
    input                      i_isBeq             ,
    input                      i_branch            ,

    
    // <-#
    output        [NB_REG-1:0] o_pc_jsel_to_IF     , //conect input2 mux_3 en IF
    output                     o_PCSrc_to_IF       , //conect sel mux_1 en IF
    output        [NB_REG-1:0] o_branch_target     , //conect input2 mux_1 en IF ,

    // #->
    output        [NB_REG-1:0] o_pcplus8           ,
    output signed [NB_REG-1:0] o_inst_sign_extended,
    output        [NB_REG-1:0] o_rs_data           ,
    output        [NB_ADDR-1:0]o_op_r_tipe         ,
    output        [NB_ADDR-1:0]o_rs_addr           ,
    output        [NB_ADDR-1:0]o_rt_addr           ,
    output        [NB_ADDR-1:0]o_rd_addr           ,
    output        [NB_REG-1:0] o_rt_data

);
wire [NB_REG-1:0] o_alu_rs_data;
wire [NB_REG-1:0] o_alu_rt_data;

sign_extend #(
    .NB_IN  (16),
    .NB_OUT (32)
) u_sign_extend (
    .i_data(i_inst_from_IF[15:0]),
    .o_data(o_inst_sign_extended)
);

register_mem #(
    .NB_REG  (NB_REG  ),
    .NB_ADDR (NB_ADDR )
) u_register_mem (
    .i_clk          (i_clk                ),
    .i_reset        (i_reset              ),
    .i_enable       (i_regWrite_from_WB   ),
    .i_dunit_clk_en (i_dunit_clk_en       ),
    .i_rs_addr      (i_inst_from_IF[25:21]),
    .i_rt_addr      (i_inst_from_IF[20:16]),
    .i_wb_addr      (i_WB_addr            ),   //from wb
    .i_wb_data      (i_WB_data            ),   //from wb
    .o_rs_data      (o_alu_rs_data        ),
    .o_rt_data      (o_alu_rt_data        )
);
assign o_pc_jsel_to_IF = o_alu_rs_data;  //conect input2 mux_3 en IF

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


wire rs_equals_rt;               // Comparación entre o_rs_data y o_rt_data
assign rs_equals_rt = | (o_rs_data ^ o_rt_data);

wire wire_to_and;                // Selección según IsBeq
mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_mpx_beq_bne
(
    .i_a       (rs_equals_rt),   
    .i_b       (~rs_equals_rt),   
    .i_sel     (i_isBeq),  
    .o_out     (wire_to_and  )  
);
assign o_PCSrc_to_IF = i_branch & wire_to_and;



//logica para calcular la dirección de salto
assign o_branch_target = i_pcplus4 + (o_inst_sign_extended << 2); // se concatena el pc+4 con la instrucción mas su desplazamiento

assign o_op_r_tipe  = i_inst_from_IF[5:0];
assign o_rs_addr    = i_inst_from_IF[25:21];
assign o_rt_addr    = i_inst_from_IF[20:16];
assign o_rd_addr    = i_inst_from_IF[15:11];

assign o_pcplus8 = i_pcplus4 + 32'h00000004;

endmodule