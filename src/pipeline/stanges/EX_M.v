module EX_M 
#(
    parameter NB_REG = 32,
    parameter NB_CTRL= 9,
    parameter NB_ADDR = 5
) (
    input                           i_clk     ,
    input                           i_reset   ,
    input                           i_dunit_clk_en,

    input           [NB_REG-1:0]    i_pc_eight,
    input           [NB_REG-1:0]    i_alu_result,
    input           [NB_REG-1:0]    i_w_data,
    input           [NB_ADDR-1:0]   i_data_addr,

    input           [NB_CTRL-1:0]   i_control_from_ex,

    output           [NB_REG-1:0]    o_pc_eight,
    output           [NB_REG-1:0]    o_alu_result,
    output           [NB_REG-1:0]    o_w_data,
    output           [NB_ADDR-1:0]   o_data_addr,

    output           [NB_CTRL-1:0]   o_control_from_ex
);

reg [NB_REG-1:0] pc_reg;
reg [NB_REG-1:0] alu_es_reg;
reg [NB_REG-1:0] w_data_reg;
reg [NB_ADDR-1:0] data_addr_reg;

reg [NB_CTRL-1:0] control_reg;




always @(posedge i_clk) begin
    if (i_reset ) begin
        pc_reg <= 32'b0;
        alu_es_reg <= 32'b0;
        w_data_reg <= 32'b0;
        data_addr_reg <= 5'b0;

        control_reg  <= 9'b0;
    end
    else if (i_dunit_clk_en) begin
        pc_reg       <= i_pc_eight;
        alu_es_reg   <= i_alu_result;
        w_data_reg   <= i_w_data;
        data_addr_reg    <= i_data_addr;

        control_reg  <= i_control_unit;


        
    end
    else begin
        pc_reg       <= pc_reg;
        alu_es_reg   <= alu_es_reg;
        w_data_reg   <= w_data_reg;
        data_addr_reg    <= data_addr_reg;

        control_reg  <= control_reg;

    end
    
end


assign o_pc_eight       = pc_reg;
assign o_alu_result     = alu_es_reg;
assign o_w_data         = w_data_reg;
assign o_data_addr      = data_addr_reg;

assign o_control_unit   = control_reg;

    
endmodule
