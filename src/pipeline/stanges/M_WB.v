module M_WB 
#(
    parameter NB_REG = 32,
    parameter NB_CTRL= 4,
    parameter NB_ADDR = 5
) (
    input                           i_clk     ,
    input                           i_reset   ,
    input                           i_dunit_clk_en,

    input           [NB_REG-1:0]    i_pc_eight,
    input           [NB_REG-1:0]    i_read_data,     // conectar entrada 1 mux
    input           [NB_REG-1:0]    i_alu_res_ex_m, // cable conectado a addr conectar entrada 0 mux
    input           [NB_ADDR-1:0]   i_data_addr_ex_m,
    input           [NB_CTRL-1:0]   i_control_from_m,



    output           [NB_REG-1:0]    o_pc_eight,
    output           [NB_REG-1:0]    o_read_data,
    output           [NB_REG-1:0]    o_alu_res_ex_m,
    output           [NB_ADDR-1:0]    o_data_addr_ex_m,
    output           [NB_CTRL-1:0]    o_control_from_m
);

reg [NB_REG-1:0]    pc_reg;
reg [NB_REG-1:0]    read_data_reg;   
reg [NB_REG-1:0]    alu_res_reg; 
reg [NB_ADDR-1:0]   data_addr_reg;
reg [NB_CTRL-1:0]   control_reg;


always @(posedge i_clk) begin
    if (i_reset ) begin
        pc_reg        <= 32'b0;
        read_data_reg <= 32'b0;
        alu_res_reg   <= 32'b0;
        data_addr_reg <=  5'b0;
        control_reg   <=  4'b0;
    end
    else if (i_dunit_clk_en) begin
        pc_reg        <= i_pc_eight;
        read_data_reg <= i_read_data;
        alu_res_reg   <= i_alu_res_ex_m;
        data_addr_reg <= i_data_addr_ex_m;
        control_reg   <= i_control_from_m;

    end
    else begin
        pc_reg          <=            pc_reg;
        read_data_reg   <=     read_data_reg;
        alu_res_reg     <=       alu_res_reg;    
        data_addr_reg   <=     data_addr_reg;
        control_reg     <=       control_reg; 
    end
    
end

assign o_pc_eight       = pc_reg;
assign o_read_data      = read_data_reg;   
assign o_alu_res_ex_m   = alu_res_reg; 
assign o_data_addr_ex_m = data_addr_reg;
assign o_control_from_m = control_reg;

endmodule
