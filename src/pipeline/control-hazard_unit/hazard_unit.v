module hazard_unit 
#(
    parameter NB_ADDR = 5 
)
(
    input                i_jump       ,
    input                i_branch     ,

    input [NB_ADDR-1:0]  i_rs_id      ,
    input [NB_ADDR-1:0]  i_rt_id      ,
    input [NB_ADDR-1:0]  i_rt_ex      ,
    input                i_mem_read_ex,  

    output               o_flush      ,
    output               o_stall
);

//read load data hazard
assign o_stall = (i_mem_read_ex) && ((i_rs_id == i_rt_ex) || (i_rt_id == i_rt_ex)); // stall if/id and pc and disable controlUnit

assign o_flush = (i_jump || i_branch); // flush if/id register
    
endmodule


