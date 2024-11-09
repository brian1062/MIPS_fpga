module register_mem 
#(
    parameter NB_REG  = 32,
    parameter NB_ADDR =  5
) (
    input                       i_clk    ,
    input                       i_reset  ,
    input                       i_enable ,
    input   [NB_ADDR - 1 : 0]   i_rs_addr,
    input   [NB_ADDR - 1 : 0]   i_rt_addr,
    input   [NB_ADDR - 1 : 0]   i_wb_addr,   //from wb
    input   [NB_REG  - 1 : 0]   i_wb_data,   //from wb
    output  [NB_REG  - 1 : 0]   o_rs_data,
    output  [NB_REG  - 1 : 0]   o_rt_data
);

reg [NB_REG-1:0] reg_mem [2**NB_ADDR-1:0];

// write in negedge clock
integer i;
always @(negedge i_clk) begin
    if (i_reset) begin
        //limpiamos la memoria
        for (i = 0; i < 2**NB_ADDR; i = i + 1) begin
            reg_mem[i] <= 0;
        end        
    end
    else if (i_enable) begin
        reg_mem[i_wb_addr] <= i_wb_data;
    end

end

assign o_rs_data = reg_mem[i_rs_addr];
assign o_rt_data = reg_mem[i_rt_addr];
    
endmodule