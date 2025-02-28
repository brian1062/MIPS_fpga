module toplevel 
#(
    parameter NB_REG = 32 ,
    parameter NB_IFID =64 ,
    parameter NB_IDEX =144,
    parameter NB_EXM  =88 ,
    parameter NB_MWB  =80 ,
    parameter NB_R_INT=376
) 
(
    input               clock       ,
    input               i_reset     ,
    input               RsRx        ,

    output              RsTx        
);

wire clk_50mhz;

wire reset_from_d_unit;
wire enable_wire;
wire [NB_REG-1:0] wire_addr;
wire [NB_REG-1:0] wire_intruction;
wire  write_mem;
wire  wire_halt;

wire [NB_REG-1:0] wire_data_mem;
wire [NB_REG-1:0] wire_reg_mem ;

//wire intermediant regs
wire [NB_IFID-1:0] w_IF_ID;
wire [NB_IDEX-1:0] w_ID_EX;
wire [NB_EXM-1:0]  w_EX_M ;
wire [NB_MWB-1:0]  w_M_WB ;
wire [NB_R_INT-1:0] w_int_reg;

clk_wiz_0 u_clk_wiz_0
 (
  // Clock out ports
        .clk_50mhz(clk_50mhz),
  // Status and control signals
        .reset(i_reset),
        .locked(),
 // Clock in ports
        .clk_in1(clock)
 );
 
debug_unit #(
    .NB_REG   (NB_REG),
    .NB_R_INT(NB_R_INT),
    .DBIT     (8  ),
    .SB_TICK  (16 ),
    .DVSR     (163), //50mhz 50mhz/(19200*16)
    .DVSR_BIT (8  ),
    .FIFO_W   (5  )
) u_debug_unit(
    .i_clk       (clk_50mhz),
    .i_reset     (i_reset),
    .i_rx        (RsRx),
    .i_reg_data  (wire_reg_mem),
    .i_mem_data  (wire_data_mem),
    .i_reg_int   (w_int_reg),
    .i_halt      (wire_halt),
    .o_tx        (RsTx),
    .o_w_mem     (write_mem),
    .o_inst      (wire_intruction),
    .o_addr_inst (wire_addr), 
    .o_enable    (enable_wire),
    .o_reset_mips(reset_from_d_unit)  
);


pipeline #(
    .NB_REG  (NB_REG),
    .NB_WIDHT(9  ), // for widht addr in instruction memory or datamemory
    .NB_OP   (6  ),
    .NB_ADDR (5  ), //for addr -> rs ,rt ..
    .NB_IFID (NB_IFID ),
    .NB_IDEX (NB_IDEX),
    .NB_EXM  (NB_EXM ),
    .NB_MWB  (NB_MWB )  
) u_pipeline(
    .i_clk           (clk_50mhz),
    .i_reset         (i_reset | reset_from_d_unit),
    .i_dunit_clk_en  (enable_wire),
    .i_dunit_reset_pc(1'b0),
    .i_dunit_w_mem   (write_mem),       //write in instruction memory
    .i_dunit_addr    (wire_addr),           //ADDR TO instruction memory, REGISTER MEMORY and datamemory
    .i_dunit_data_if (wire_intruction),        //instruction memory
    .o_dunit_reg     (wire_reg_mem),       //registermemory TO DEBUG UNIT  
    .o_dunit_mem_data(wire_data_mem),       //datamemory TO DEBUG UNIT
    .o_IF_ID         (w_IF_ID),
    .o_ID_EX         (w_ID_EX),
    .o_EX_M          (w_EX_M),
    .o_M_WB          (w_M_WB),
    .o_halt          (wire_halt)
);
assign w_int_reg = {w_IF_ID, w_ID_EX, w_EX_M, w_M_WB};
    
endmodule