`timescale 1ns / 1ps
module IF
#(
    parameter               NB_REG  = 32,
    parameter               NB_WIDHT = 9,
    parameter               NB_INST = 26

)
 (
    input                   i_clk               ,
    input                   i_reset             ,
    input                   i_dunit_clk_en      ,
    input                   i_dunit_w_en        ,
    input  [NB_WIDHT-1:0]   i_dunit_addr        ,
    input                   i_PCSrc             ,
    input                   i_Jump              ,
    input                   i_JSel              ,
    input                   i_PCWrite           ,
    input  [NB_REG-1:0 ]    i_inmed             ,
    input  [NB_INST-1:0]    i_inst_to_mxp       ,
    input  [NB_REG-1:0 ]    i_pc_jsel           ,
    input  [NB_REG-1:0 ]    i_dunit_data        ,                
    output [NB_REG-1:0 ]    o_pcplus4            ,
    output [NB_REG-1:0 ]    o_instruction
);

wire [NB_REG-1:0] pc_to_mem     ;
wire [NB_REG-1:0] mpx3_to_pc    ;
wire [NB_REG-1:0] mpx2_to_mpx3  ;
wire [NB_REG-1:0] mpx1_to_mpx2  ;

mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_mpx_1
(
    .i_a       (o_pcplus4),   
    .i_b       (i_inmed),   
    .i_sel     (i_PCSrc),  
    .o_out     (mpx1_to_mpx2)  
);

mpx_2to1 #(
    .NB_INPUT(NB_REG)          
) u_mpx_2
(
    .i_a       (mpx1_to_mpx2),   
    .i_b       ( {o_pcplus4[31:28], i_inst_to_mxp, 2'b00}),  // se concatena el pc+4 con la instrucción mas su desplazamiento  
    .i_sel     (i_Jump),  
    .o_out     (mpx2_to_mpx3)  
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
// Instanciación del módulo pc
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

adder_four #(
    .ADDER_WIDTH(NB_REG) 
) u_adder_four (
    .a_input     (pc_to_mem         ),
    .sum         (o_pcplus4          )
);


ram_async_single_port #(
      .NB_WIDHT  (NB_REG   ),
      .NB_ADDR   (NB_WIDHT ), //512 posiciones
      .NB_DATA   (8        )  //8 bits de ancho
) u_instruction_memory (
      .i_clk       (i_clk       ),
      .i_reset     (i_reset     ),
      .i_we        (i_dunit_w_en),
      .i_addr      (pc_to_mem[NB_WIDHT-1:0] ),
      .i_data_in   (i_dunit_data),
      .o_data_out  (o_instruction)
  );  
    
endmodule