module register #(
    parameter NB_REG = 8
)(
    input                       i_clk,
    input                       i_reset,
    input                       i_enable,
    input   [NB_REG - 1 : 0]    i_data,
    output  [NB_REG - 1 : 0]    o_data
);

reg [NB_REG - 1 : 0]  regist;
always @(posedge i_clk)
    begin
        if (i_reset)begin
            regist <= 0;
        end
        else if (i_enable)begin
            regist <= i_data;
        end
        else
            regist <= regist;            
    end

assign o_data = regist;

endmodule