module ID_EX 
#(
    parameter NB_REG = 32,
    parameter NB_CTRL= 18, //ver bien
    parameter NB_ADDR = 5
) (
    input                           i_clk     ,
    input                           i_reset   ,
    input                           i_dunit_clk_en,

    input           [NB_REG-1:0]    i_pc_eight,
    input           [NB_REG-1:0]    i_rs_data ,
    input           [NB_REG-1:0]    i_rt_data ,
    input  signed   [NB_REG-1:0]    i_sign_extension,
    input           [NB_CTRL-1:0]   i_control_unit,

    output           [NB_REG-1:0]    o_pc_eight,
    output           [NB_REG-1:0]    o_rs_data ,
    output           [NB_REG-1:0]    o_rt_data ,
    output  signed   [NB_REG-1:0]    o_sign_extension,
    output           [NB_CTRL-1:0]   o_control_unit
);

reg [NB_REG-1:0] pc_reg;
reg [NB_REG-1:0] rs_reg;
reg [NB_REG-1:0] rt_reg;
reg [NB_CTRL-1:0] control_reg;
reg signed [NB_REG-1:0] sign_ext_reg;

always @(posedge i_clk) begin
    if (i_reset || i_flush) begin
        pc_reg <= 32'b0;
        rs_reg       <= 32'b0;
        rt_reg       <= 32'b0;
        sign_ext_reg <= 32'b0;
        control_reg  <= 18'b0;
    end
    else if (i_dunit_clk_en) begin
        pc_reg       <= i_pc_eight;
        rs_reg       <= i_rs_data;
        rt_reg       <= i_rt_data;
        sign_ext_reg <= i_sign_extension;
        control_reg  <= i_control_unit;

        
    end
    else begin
        pc_reg       <= pc_reg;
        rs_reg       <= rs_reg;
        rt_reg       <= rt_reg;
        sign_ext_reg <= sign_ext_reg;
        control_reg  <= control_reg;
    end
    
end


assign o_pc_eight       = pc_reg;
assign o_rs_data        = rs_reg;
assign o_rt_data        = rt_reg;
assign o_sign_extension = sign_ext_reg;
assign o_control_unit   = control_reg;
    
endmodule
