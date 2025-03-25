Copy

//===========================================
// Module: debug_unit
// Description:
//    Manages communication between a host and the MIPS processor via UART.
//    Handles program loading, step-by-step execution, runtime monitoring, 
//    and debugging. Interfaces with registers, memory, and internal pipeline 
//    states for data exchange and control.
// Author: Brian Gerard
// Created: 12/02/2025
// Parameters:
// - NB_REG: Bit width for registers and data buses (default: 32).
// - NB_R_INT: Bit width for internal register snapshot (default: 376).
// - DBIT: Number of data bits per UART frame (default: 8).
// - SB_TICK: Stop bit ticks for UART (default: 16).
// - DVSR: Baud rate divisor (Clock/(BaudRate*16)) (default: 326).
// - DVSR_BIT: Bit width for baud rate divisor (default: 9).
// - FIFO_W: FIFO buffer depth (2^FIFO_W entries) (default: 5).
// Inputs:
// - i_clk: System clock signal.
// - i_reset: Global reset signal.
// - i_rx: UART receive data line.
// - i_reg_data: Register data from MIPS for debugging.
// - i_mem_data: Data memory contents for debugging.
// - i_reg_int: Internal pipeline register states for debugging.
// - i_halt: Signal indicating processor halt.
// Outputs:
// - o_tx: UART transmit data line.
// - o_w_mem: Write enable for instruction memory.
// - o_inst: Instruction data to be written to memory.
// - o_addr_inst: Address for instruction memory access.
// - o_enable: Processor execution enable signal.
// - o_reset_mips: Reset signal for MIPS processor.
//===========================================
module debug_unit 
#(
    parameter NB_REG  = 32,
    parameter NB_R_INT=376,
    parameter DBIT    = 8 ,
    parameter SB_TICK = 16,
    parameter DVSR    = 326,
    parameter DVSR_BIT= 9  ,
    parameter FIFO_W  = 5  
) 
(
    input               i_clk       ,
    input               i_reset     ,

    input               i_rx        ,
    input [NB_REG-1:0] i_reg_data   ,
    input [NB_REG-1:0] i_mem_data   ,
    input [NB_R_INT-1:0]i_reg_int   , 
    input               i_halt      ,

    output              o_tx        ,
    output              o_w_mem     ,
    output[NB_REG-1:0]  o_inst      ,
    output[NB_REG-1:0]  o_addr_inst , 
    output              o_enable    ,
    output              o_reset_mips  
);

wire fifo_rx_empty;
wire fifo_tx_full;
wire [DBIT-1:0] read_data;
wire [DBIT-1:0] tx_data;
wire rd_uart_wire, wr_uart_wire;

 
UART #(//19200 bauds, databit,1stopbit 2^2 FIFO
    .DBIT     (DBIT   ),      //! DATA BIT
    .SB_TICK  (SB_TICK),      //! STICKS FOR STOP BITS
    .DVSR     (DVSR   ),      //! baud rate divisor ( Clock/(BaudRate*16) )
    .DVSR_BIT (DVSR_BIT),      //! bits of divisor representa en cuanto bits entra el dvsr
    .FIFO_W   (FIFO_W)       //! FIFO width FIFO=2^FIFO_W
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


//! state params
localparam IDLE         = 8'b0000_0001;
localparam START        = 8'b0000_0010;
localparam RUN          = 8'b0000_0011;
localparam LOAD_PROG    = 8'b0000_0100;
localparam STEP         = 8'b0000_0101;
localparam SEND         = 8'b0000_0110;
localparam SEND_M       = 8'b0000_0111;
localparam SEND_REG     = 8'b0000_1000;
localparam SEND_REG_INT = 8'b0000_1110;
localparam WAIT_RX      = 8'b0000_1001;
localparam WAIT_TX      = 8'b0000_1010;
localparam WRITE_INST   = 8'b0000_1011;
localparam RESET        = 8'b0000_1100;
localparam RETURN       = 8'b0000_1101;
localparam HALT_CODE    = 32'h3f;


//! var
reg [1:0] counter  , next_counter  ;
reg [DBIT-1:0] state    , next_state    ;
reg [DBIT-1:0] waiting_state , next_waiting_state;
reg step_mode, next_step_mode;
reg enable,  reset, write_mem, rd_reg, wr_reg;
reg [NB_REG-1:0] inst_to_mem, next_inst_to_mem; 
reg [NB_REG-1:0] addr_inst, next_addr_inst; 
reg [NB_REG-1:0] data_to_tx, next_data_to_tx; 

always @(posedge i_clk) begin : update_regs
    if (i_reset) begin
        state <= IDLE;
        waiting_state <= IDLE;
        counter <= 2'b00;
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
                    if (addr_inst == 31) begin
                        next_addr_inst = 0;
                        next_state = SEND_M;
                    end
                    else begin
                        next_addr_inst = addr_inst +1;
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
                    if (addr_inst[6:0] == 7'b1111100) begin //1111100
                        next_addr_inst = 0;
                        next_state = SEND_REG_INT;
                    end
                end
            end   
        end
        SEND_REG_INT:
        begin
            if(fifo_tx_full)begin
                next_state = WAIT_TX;
                next_waiting_state = SEND_REG_INT;
            end
            else begin
                next_data_to_tx = i_reg_int[(375-addr_inst*8)-:8];//prueba usar el addr como contador, para no crear otro
                next_addr_inst = addr_inst +1;
                if (addr_inst == 46) begin
                    next_addr_inst = 0;
                    next_state = RETURN;
                end
            end
        end

        RETURN:
        begin
            if(fifo_tx_full)begin
                next_state = WAIT_TX;
                next_waiting_state = RETURN;
            end
            else begin
                if(step_mode) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = RESET;
                end
            end
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
    IDLE, WAIT_RX, WAIT_TX:
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
    SEND:
    begin
        rd_reg = 1'b0;
        wr_reg = 1'b0;
        write_mem = 1'b0;
        enable = 1'b0;
        reset = 1'b0;
    end
    SEND_M, SEND_REG, SEND_REG_INT, RETURN:
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
        wr_reg = 1'b0;
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

//!
assign rd_uart_wire = rd_reg;
assign wr_uart_wire = wr_reg;
assign tx_data  = data_to_tx;
assign o_inst = inst_to_mem; //instructions to mem
assign o_addr_inst = addr_inst;
assign o_enable = enable;
assign o_reset_mips = reset;
assign o_w_mem = write_mem;

endmodule