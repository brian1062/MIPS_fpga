module pc 
#(
    parameter PC_WIDTH = 32
)
(
    input       i_clk,
    input       i_reset,
    input       i_enable,
    input       PCWrite,
    input       [PC_WIDTH-1:0] pc_in,
    output      [PC_WIDTH-1:0] pc_out
);

    reg [PC_WIDTH-1:0] pc;


    always @(posedge i_clk or posedge i_reset)
    begin
        if (i_reset)
            pc <= 32'd0;
        else if (i_enable && PCWrite)
            pc <= pc_in;
        else
            pc <= pc;
    end

    initial begin
        pc <= 0;
    end

    assign pc_out = pc;

    
endmodule