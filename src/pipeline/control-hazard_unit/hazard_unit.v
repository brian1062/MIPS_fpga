module hazard_unit 
#(
    parameter NB_ADDR = 5 
)
(
    // input                i_jump       ,
    input                i_branch     ,

    input [NB_ADDR-1:0]  i_rs_id      ,
    input [NB_ADDR-1:0]  i_rt_id      ,
    input [NB_ADDR-1:0]  i_rt_ex      ,
    input [NB_ADDR-1:0]  i_rd_ex      ,
    input [NB_ADDR-1:0]  i_rd_mem     ,
    input                i_mem_read_ex, //load operations   |memread_e writereg_m  regwrite_E  memread_m
    input                i_regwrite_ex,  //writereg_e
    input                i_memtoreg_m , 

    output               o_flush_idex,
    output               o_stall
);


reg reg_flush;
reg reg_stall;
always @(*) begin
    //read load data hazard
    if((i_mem_read_ex) && ((i_rs_id == i_rt_ex) || (i_rt_id == i_rt_ex)))
    begin
        reg_flush = 1'b1;
        reg_stall = 1'b1;
    end

    else if(i_branch && (
        (i_regwrite_ex && (i_rd_ex != 5'b00000) &&
        ((i_rd_ex == i_rs_id)|| (i_rd_ex == i_rt_id)))
        ||
        (i_memtoreg_m && (i_rd_mem != 5'b00000) &&    
        ((i_rd_mem == i_rs_id) || (i_rd_mem == i_rt_id)))
    ))
        begin
            reg_flush = 1'b1;
            reg_stall = 1'b1;
        end
    else begin
        reg_flush = 1'b0;
        reg_stall = 1'b0;
    end
    
end

assign o_flush_idex = reg_flush;
assign o_stall      = reg_stall;

    
endmodule


