module toplevel 
#(
    parameter NB_REG = 32
) 
(
    input               clock       ,
    input               i_reset     ,
    input               RsRx        ,

    output              RsTx        
);

wire clk_50mhz;

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
    .i_halt      (wire_halt),
    .o_tx        (RsTx),
    .o_w_mem     (write_mem),
    .o_inst      (wire_intruction),
    .o_addr_inst (wire_addr), 
    .o_enable    (enable_wire),
    .o_reset_mips(reset_from_d_unit)  
);
wire reset_from_d_unit;
wire enable_wire;
wire [NB_REG-1:0] wire_addr;
wire [NB_REG-1:0] wire_intruction;
wire  write_mem;
wire  wire_halt;

wire [NB_REG-1:0] wire_data_mem;
wire [NB_REG-1:0] wire_reg_mem ;

pipeline #(
    .NB_REG  (NB_REG),
    .NB_WIDHT(9 ), // for widht addr in instruction memory or datamemory
    .NB_OP   (6 ),
    .NB_ADDR (5 ) //for addr -> rs ,rt ..
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
    .o_halt          (wire_halt)


);
    
endmodule