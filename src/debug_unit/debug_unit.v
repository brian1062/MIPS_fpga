module debug_unit 
#(
    parameter NB      = 8 ,
    parameter NB_DATA = 32,
    parameter SB_TICK = 16,
    parameter DVSR    = 326,
    parameter NB_REG  = 32
) 
(
    input               i_clk       ,
    input               i_reset     ,

    input               i_rx        ,
    input [NB_DATA-1:0] i_reg_data  ,
    input [NB_DATA-1:0] i_mem_data  ,
    input               i_halt      ,

    output              o_tx        ,
    output              o_w_mem     ,
    output[NB_REG-1:0]  o_inst      ,
    output[NB_REG-1:0]  o_addr_inst , 
    output              o_enable    ,
    output              o_reset_mips  


);
 
UART #(//19200 bauds, databit,1stopbit 2^2 FIFO
    .DBIT     (NB     ),      //! DATA BIT
    .SB_TICK  (SB_TICK),      //! STICKS FOR STOP BITS
    .DVSR     (DVSR   ),      //! baud rate divisor ( Clock/(BaudRate*16) )
    .DVSR_BIT (  9),      //! bits of divisor representa en cuanto bits entra el dvsr
    .FIFO_W   (  5)       //! FIFO width FIFO=2^FIFO_W
) u_uart (
    .clk     (i_clk),  //! clock 
    .reset   (i_reset),  //! reset
    .rd_uart (rd_uart_wire),  //! read uart
    .wr_uart (wr_uart_wire),  //! write uart
    .rx      (i_rx),  //! rx
    .w_data  (tx_data),  //! data to write
    .tx_full (fifo_tx_full),  //! tx full     output
    .rx_empty(fifo_rx_empty),  //! rx empty fifo   output
    .tx      (o_tx),  //! tx               output
    .r_data  (read_data)//! data to read  output
);

wire fifo_rx_empty;
wire fifo_tx_full;
wire [NB-1:0] read_data;
wire [NB-1:0] tx_data;
wire rd_uart_wire, wr_uart_wire;

//! state params
localparam IDLE         = 8'b0000_0001;
localparam START        = 8'b0000_0010;
localparam RUN          = 8'b0000_0011;
localparam LOAD_PROG    = 8'b0000_0100;
localparam STEP         = 8'b0000_0101;
localparam SEND         = 8'b0000_0110;
localparam SEND_M       = 8'b0000_0111;
localparam SEND_REG     = 8'b0000_1000;
localparam WAIT_RX      = 8'b0000_1001;
localparam WAIT_TX      = 8'b0000_1010;
localparam WRITE_INST   = 8'b0000_1011;
localparam RESET        = 8'b0000_1100;
localparam RETURN       = 8'b0000_1101;
localparam HALT_CODE    = 32'h3f;

//!
assign rd_uart_wire = rd_reg;
assign wr_uart_wire = wr_reg;
assign tx_data  = data_to_tx;
assign o_inst = inst_to_mem; //instructions to mem
assign o_addr_inst = addr_inst;
assign o_enable = enable;
assign o_reset_mips = reset;
assign o_w_mem = write_mem;
//! var
reg [NB_REG-1:0] counter  , next_counter  ;
reg [NB-1:0] state    , next_state    ;
reg [NB-1:0] waiting_state , next_waiting_state;
reg step_mode, next_step_mode;
reg enable,  reset, write_mem, rd_reg, wr_reg;
reg [NB_REG-1:0] inst_to_mem, next_inst_to_mem; 
reg [NB_REG-1:0] addr_inst, next_addr_inst; 
reg [NB_REG-1:0] data_to_tx, next_data_to_tx; 

always @(posedge i_clk) begin : update_regs
    if (i_reset) begin
        state <= IDLE;
        waiting_state <= IDLE;
        counter <= 0;
        step_mode <= 1'b0;
        inst_to_mem <= 0;
        addr_inst <= 0;
        data_to_tx <= 8'b0;


    end
    else begin
        counter <= next_counter;
        state <= next_state;
        waiting_state <= next_waiting_state;
        step_mode <= next_step_mode;
        inst_to_mem <= next_inst_to_mem;
        addr_inst <= next_addr_inst;
        data_to_tx <= next_data_to_tx;
    end
end

//! next_state_logic
always @(*) begin  
    next_state = state;
    next_counter = counter;
    next_addr_inst = addr_inst;
    next_inst_to_mem = inst_to_mem;
    next_waiting_state = waiting_state;
    next_step_mode = step_mode;
    next_data_to_tx = data_to_tx;
    case (state)
        IDLE:
        begin
            next_addr_inst = 0;
            next_counter = 0;
            if (!fifo_rx_empty) begin
                next_state = START;
            end
        end
        START:
        begin
            if (fifo_rx_empty) begin
                next_state = WAIT_RX;
                next_waiting_state = START;
            end
            if (read_data == LOAD_PROG) begin
                next_state = LOAD_PROG;
            end
            else if (read_data == STEP) begin
                next_state = STEP;
                next_step_mode = 1'b1;
            end
            else if (read_data == RUN) begin
                next_state = RUN;
                next_step_mode = 1'b0;
            end
            else if (read_data == RESET) begin
                next_state = RESET;
            end
            else begin
                next_state = IDLE;
            end
        end
        LOAD_PROG:
        begin
            if (fifo_rx_empty) begin
                next_state = WAIT_RX;
                next_waiting_state = LOAD_PROG;
            end
            else begin
                next_inst_to_mem = {inst_to_mem[23:0],read_data};
                next_counter = counter + 1;
                if (counter[1:0] == 2'b11) begin
                    next_counter = 0;
                    next_state = WRITE_INST;
                end
            end
        end
        WRITE_INST:
        begin
            if (inst_to_mem == HALT_CODE) begin
                next_state =  START;
                next_addr_inst= 0;
            end
            else begin
                next_addr_inst = addr_inst + 4;
                next_state = LOAD_PROG;
            end
        end
        WAIT_RX:
        begin
            if(!fifo_rx_empty) begin
                next_state = waiting_state;
            end
        end
        WAIT_TX:
        begin
            if(!fifo_tx_full)begin
                next_state = waiting_state;
            end
        end
        STEP:
        begin
            next_state = SEND;//estado de escritura
            if(i_halt)begin
                next_step_mode = 1'b0;
            end

        end
        RUN:
        begin
            if(i_halt)begin
                next_state = SEND;
            end
        end
        SEND:
        begin
            if(fifo_tx_full)begin
                next_state = WAIT_TX;
                next_waiting_state = SEND;
            end
            else begin
                next_data_to_tx = i_reg_data[(31-counter[1:0]*8)-:8];
                next_counter = counter + 1;
                next_state = SEND_REG;
            end
        end
        SEND_REG:
        begin
            if(fifo_tx_full)begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_REG;
            end
            else begin
                next_data_to_tx = i_reg_data[(31-counter[1:0]*8)-:8];
                next_counter = counter +1;
                if (counter[1:0] == 2'b11) 
                begin
                    next_counter = 0;
                    next_addr_inst = addr_inst +1;
                    if (addr_inst == 31) begin
                        next_addr_inst = 0;
                        next_state = SEND_M;
                    end
                end
            end
        end
        SEND_M:
        begin
            if(fifo_tx_full)begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_M;
            end
            else begin
                next_data_to_tx = i_mem_data[(31-counter[1:0]*8)-:8];
                next_counter = counter +1;
                if (counter [1:0] == 2'b11) 
                begin
                    next_counter = 0;
                    next_addr_inst = addr_inst +4; // en data va de a 4
                    if (addr_inst == 512) begin
                        next_addr_inst = 0;
                        next_state = RETURN;
                    end
                end
            end   
        end
        //TODO: SEND IF_ID ID_EX EX_M M_WB
        RETURN:
        begin
            // if(fifo_tx_full)begin
            //     next_state = WAIT_TX;
            //     next_waiting_state = RETURN;
            // end
            // else begin
            if(step_mode) begin
                next_state = IDLE;
            end
            else begin
                next_state = RESET;
            end
            // end
        end

        RESET:
        begin
            next_state = IDLE;
        end
        default: 
        begin
            next_state = IDLE;
        end
    endcase
end

//! output_logic
always @(*) begin  
    case (state)
    START:
    begin
        rd_reg = 1'b1;
        wr_reg = 1'b0;
        write_mem = 1'b0;
        enable = 1'b0;
        reset = 1'b0;    
    end
    LOAD_PROG:
    begin
        rd_reg = 1'b1;
        wr_reg = 1'b0;
        write_mem = 1'b0;
        enable = 1'b0;
        reset = 1'b0;  
    end
    WRITE_INST:
    begin
        rd_reg = 1'b0;
        wr_reg = 1'b0;
        write_mem = 1'b1;
        enable = 1'b0;
        reset = 1'b0;
    end
    IDLE, WAIT_RX, WAIT_TX, RETURN:
    begin
        rd_reg = 1'b0;
        wr_reg = 1'b0;
        write_mem = 1'b0;
        enable = 1'b0;
        reset = 1'b0;
    end
    RUN, STEP:
    begin
        rd_reg = 1'b0;
        wr_reg = 1'b0;
        write_mem = 1'b0;
        enable = 1'b1;
        reset = 1'b0;
    end
    SEND, SEND_M, SEND_REG:
    begin
        rd_reg = 1'b0;
        wr_reg = 1'b1;
        write_mem = 1'b0;
        enable = 1'b0;
        reset = 1'b0;
    end
    RESET:
    begin
        rd_reg = 1'b0;
        wr_reg = 1'b1;
        write_mem = 1'b0;
        enable = 1'b0;
        reset = 1'b1;
    end
    default:
    begin
        rd_reg = 1'b0;
        wr_reg = 1'b0;
        write_mem = 1'b0;
        enable = 1'b0;
        reset = 1'b0;
    end 
    endcase
end

endmodule