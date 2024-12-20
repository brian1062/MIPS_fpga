module ID_EX 
#(
    parameter NB_REG = 32,
    parameter NB_CTRL= 16, //ver bien
    parameter NB_OP  =  6,
    parameter NB_ADDR = 5
) (
    input                           i_clk               ,
    input                           i_reset             ,
    input                           i_dunit_clk_en      ,

    input           [NB_REG -1:0]   i_pc_eight          ,
    input           [NB_REG -1:0]   i_rs_data           ,
    input           [NB_REG -1:0]   i_rt_data           ,
    input  signed   [NB_REG -1:0]   i_sign_extension    ,
    input           [NB_CTRL-1:0]   i_control_unit      ,
    input           [NB_OP  -1:0]   i_operation         ,
    input           [NB_ADDR-1:0]   i_rs_addr           ,
    input           [NB_ADDR-1:0]   i_rt_addr           ,
    input           [NB_ADDR-1:0]   i_rd_addr           ,

    output          [NB_REG -1:0]   o_pc_eight          ,
    output          [NB_REG -1:0]   o_rs_data           ,
    output          [NB_REG -1:0]   o_rt_data           ,
    output  signed  [NB_REG -1:0]   o_sign_extension    ,
    output          [NB_CTRL-1:0]   o_control_unit      ,
    output          [NB_OP  -1:0]   o_operation         ,
    output          [NB_ADDR-1:0]   o_rs_addr           ,
    output          [NB_ADDR-1:0]   o_rt_addr           ,
    output          [NB_ADDR-1:0]   o_rd_addr           
);

reg [NB_REG-1:0] pc_reg;
reg [NB_REG-1:0] rs_reg;
reg [NB_REG-1:0] rt_reg;
reg [NB_CTRL-1:0] control_reg;
reg signed [NB_REG-1:0] sign_ext_reg;

reg [NB_ADDR-1:0] addr_rs;
reg [NB_ADDR-1:0] addr_rt;
reg [NB_ADDR-1:0] addr_rd;
reg [NB_OP  -1:0] op_reg;

always @(posedge i_clk) begin
    if (i_reset ) begin
        pc_reg <= 32'b0;
        rs_reg       <= 32'b0;
        rt_reg       <= 32'b0;
        sign_ext_reg <= 32'b0;
        control_reg  <= 16'b0;
        addr_rs      <=  5'b0;
        addr_rt      <=  5'b0;
        addr_rd      <=  5'b0;
        op_reg       <=  6'b0;
    end
    else if (i_dunit_clk_en) begin
        pc_reg       <= i_pc_eight;
        rs_reg       <= i_rs_data;
        rt_reg       <= i_rt_data;
        sign_ext_reg <= i_sign_extension;
        control_reg  <= i_control_unit;
        addr_rs      <= i_rs_addr; 
        addr_rt      <= i_rt_addr;
        addr_rd      <= i_rd_addr;
        op_reg       <= i_operation;
        
    end
    else begin
        pc_reg       <= pc_reg;
        rs_reg       <= rs_reg;
        rt_reg       <= rt_reg;
        sign_ext_reg <= sign_ext_reg;
        control_reg  <= control_reg;
        addr_rs      <= addr_rs;
        addr_rt      <= addr_rt;
        addr_rd      <= addr_rd;
        op_reg       <= op_reg ;
    end
    
end


assign o_pc_eight       = pc_reg;
assign o_rs_data        = rs_reg;
assign o_rt_data        = rt_reg;
assign o_sign_extension = sign_ext_reg;
assign o_control_unit   = control_reg;
assign o_rs_addr        = addr_rs;
assign o_rt_addr        = addr_rt;
assign o_rd_addr        = addr_rd;
assign o_operation      = op_reg;
    
endmodule
