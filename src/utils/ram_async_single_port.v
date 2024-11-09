module ram_async_single_port 
#(
    parameter NB_WIDHT = 32,
    parameter NB_ADDR =  9 , //512 posiciones
    parameter NB_DATA =  8   //8 bits de ancho
)
(
    input                   i_clk       ,
    input                   i_reset     ,
    input                   i_we        ,
    input  [NB_ADDR-1:0]    i_addr      ,
    input  [NB_WIDHT-1:0]   i_data_in   ,
    output [NB_WIDHT-1:0]   o_data_out
);  

reg [NB_DATA-1:0] memory [2**NB_ADDR-1:0];

integer i;
always @(posedge i_clk) begin
    if (i_reset) begin
        for (i = 0; i < 2**NB_ADDR; i = i + 1) begin
            memory[i] <= 0;
        end
    end
    if (i_we) begin
        memory[i_addr  ] <= i_data_in[31:24];
        memory[i_addr+1] <= i_data_in[23:16];
        memory[i_addr+2] <= i_data_in[15:8 ];
        memory[i_addr+3] <= i_data_in[7 :0 ];
    end
end

assign o_data_out = {memory[i_addr], memory[i_addr+1], memory[i_addr+2], memory[i_addr+3]};

    
endmodule