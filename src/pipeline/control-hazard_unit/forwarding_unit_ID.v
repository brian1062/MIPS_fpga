module forwarding_unit_ID 
#(
    parameter NB_ADDR  =    5
) 
(
    input [NB_ADDR-1:0]     i_rs_id           , 
    input [NB_ADDR-1:0]     i_rt_id           ,  
    input [NB_ADDR-1:0]     i_rd_ex_m         ,
    input                   i_regWrite_ex_m   ,  

    output                  o_forwardA_ID     ,
    output                  o_forwardB_ID

);

assign o_forwardA_ID = (i_rs_id == i_rd_ex_m) && i_regWrite_ex_m;
assign o_forwardB_ID = (i_rt_id == i_rd_ex_m) && i_regWrite_ex_m;
    
endmodule