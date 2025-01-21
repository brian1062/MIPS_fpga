module UART
#(//19200 bauds, databit,1stopbit 2^2 FIFO
    parameter DBIT     =  32,      //! DATA BIT
    parameter SB_TICK  =  16,      //! STICKS FOR STOP BITS
    parameter DVSR     = 326,      //! baud rate divisor ( Clock/(BaudRate*16) )
    parameter DVSR_BIT =   9,      //! bits of divisor
    parameter FIFO_W   =   2       //! FIFO width FIFO=2^FIFO_W
) 
(
    input                    clk,  //! clock
    input                  reset,  //! reset
    input                rd_uart,  //! read uart
    input                wr_uart,  //! write uart
    input                     rx,  //! rx
    input  [DBIT-1:0]     w_data,  //! data to write
    output               tx_full,  //! tx full
    output              rx_empty,  //! rx empty
    output                    tx,  //! tx
    output [DBIT-1:0]     r_data  //! data to read
);

//sygnal declaration
wire            tick              ;
wire            rx_done_tick      ;
wire            tx_done_tick      ;
wire            tx_empty          ;
wire            tx_fifo_not_empty ;
wire [DBIT-1:0] tx_fifo_out       ;
wire [DBIT-1:0] rx_data_out       ;

//body
baud_rate_gen 
#( 
    .NB(DVSR_BIT),  // number of bits in counter //aplicar log2(M)=NB
    .M (DVSR)   // mod-M 
)
  u_baud_rate_gen
    ( 
    .clk     (clk  ),
    .reset   (reset), 
    .max_tick(tick ), 
    .q       (     )  
    );

uart_rx
#(
    .DBIT    (DBIT   ),  // # data bit 
    .SB_TICK (SB_TICK)   // # ticks for stop bits
)
  u_uart_rx
    (
    .clk         (clk           ), 
    .reset       (reset         ),
    .rx          (rx            ), 
    .s_tick      (tick          ),
    .rx_done_tick(rx_done_tick  ),
    .dout        (rx_data_out   )
    );

fifo
#(
    .B(DBIT     ), //number bits in a word
    .W(FIFO_W   )  //number of address bits
)
  u_fifo_rx
(
    .clk   (clk         ),
    .reset (reset       ),
    .rd    (rd_uart     ),
    .wr    (rx_done_tick),
    .w_data(rx_data_out ),
    .empty (rx_empty    ),
    .full  (            ),
    .r_data(r_data      )
);

fifo
#(
    .B(DBIT     ), //number bits in a word
    .W(FIFO_W   )  //number of address bits
)
  u_fifo_tx
(
    .clk   (clk         ),
    .reset (reset       ),
    .rd    (tx_done_tick),
    .wr    (wr_uart     ),
    .w_data(w_data      ),
    .empty (tx_empty    ),
    .full  (tx_full     ),
    .r_data(tx_fifo_out )
);

uart_tx 
#(
    .DBIT    (DBIT     ),   //!Data bit
    .SB_TICK (SB_TICK  )    //! Sticks for stop bits
)
  u_uart_tx
(
    .clk         (clk               ),
    .reset       (reset             ),
    .tx_start    (tx_fifo_not_empty ),
    .s_tick      (tick              ),
    .din         (tx_fifo_out       ),
    .tx_done_tick(tx_done_tick      ),
    .tx          (tx                )
);

assign tx_fifo_not_empty = ~tx_empty;

endmodule