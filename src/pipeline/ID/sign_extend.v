module sign_extend #(
    parameter NB_IN =  16,
    parameter NB_OUT = 32
) (
    input  [NB_IN -1:0] i_data,
    output [NB_OUT-1:0] o_data
);
assign o_data = {{NB_IN{i_data[NB_IN-1]}}, i_data}; //o_data = {{16{i_data[15]}}, i_data};
    
endmodule