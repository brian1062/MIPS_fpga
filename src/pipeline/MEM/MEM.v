`timescale 1ns/1ps

/////////////////////////////////////////////////////////////
// Module: MEM
// Description: Memory stage module for a pipelined processor.
//              Handles data memory operations (load/store) 
//              based on control signals and BHW encoding.
// Author: Emanuel Rodriguez
// Created: 26/11/2024
// Parameters:
//   - NB_WIDTH: Bit-width of data lines (default: 32).
//   - NB_ADDR: Bit-width of memory addresses (default: 9).
//   - NB_DATA: Bit-width of memory elements (default: 8).
// Inputs:
//   - i_clk: Clock signal.
//   - i_reset: Reset signal.
//   - i_mem_addr: Address for memory access.
//   - i_mem_data: Data to write into memory.
//   - i_mem_read_CU: Control signal to enable reading.
//   - i_mem_write_CU: Control signal to enable writing.
//   - i_BHW_CU: Control signal for byte/halfword/word operations.
// Outputs:
//   - o_read_data: Data read from memory.
/////////////////////////////////////////////////////////////

module MEM #(
    parameter NB_WIDTH = 32 ,    // Data width
    parameter NB_ADDR  = 9  ,     // Address width
    parameter NB_DATA  = 8        // Memory element width
)(
    input                   i_clk           ,            // Clock signal
    input                   i_reset         ,          // Reset signal
    input  [NB_WIDTH-1:0]   i_mem_addr      ,       // Address for memory access
    input  [NB_WIDTH-1:0]   i_mem_data      ,       // Data to write
    input                   i_mem_read_CU   ,    // Read enable
    input                   i_mem_write_CU  ,   // Write enable
    input  [2:0]            i_BHW_CU        ,         // Byte/halfword/word control signal
    input  [NB_WIDTH-1:0]   i_dunit_addr_data,
    output [NB_WIDTH-1:0]   o_read_data     ,       // Data read
    output [NB_WIDTH-1:0]   o_dunit_mem_data
);

/////////////////////////////////////////////////////////////
// Internal Signals
/////////////////////////////////////////////////////////////
wire [NB_WIDTH-1:0] mem_data_out;       // Data read from memory
wire [NB_WIDTH-1:0] data_to_mem;
reg  [NB_WIDTH-1:0] mem_data_in;        // Data to write to memory
reg  [NB_WIDTH-1:0] read_data  ;

/////////////////////////////////////////////////////////////
// Memory Instance
/////////////////////////////////////////////////////////////
ram_async_single_port #(
    .NB_WIDHT(NB_WIDTH),
    .NB_ADDR (NB_ADDR ),
    .NB_DATA (NB_DATA )
) u_ram (
    .i_clk     (i_clk),
    .i_reset   (i_reset),
    .i_we      (i_mem_write_CU),
    .i_addr    (i_mem_addr[NB_ADDR-1:0]),
    .i_data_in (data_to_mem),
    .i_dunit_addr(i_dunit_addr_data[NB_ADDR-1:0]),
    .o_data_out(mem_data_out),
    .o_data_to_dunit(o_dunit_mem_data)
);



always @(*) begin
    if (i_reset) begin
        read_data = 32'b0; // Default output
        mem_data_in = 32'b0;
    end

    case (i_BHW_CU)
        3'b000: begin
            read_data = {{24{mem_data_out[7]}}, mem_data_out[7:0]};  // LB
            mem_data_in  <= {24'b0, i_mem_data[7:0]};                //SB
        end
        3'b001: begin
            read_data = {{16{mem_data_out[15]}}, mem_data_out[15:0]}; // LH
            mem_data_in  <= {16'b0, i_mem_data[15:0]};                //SH
        end
        3'b011: begin
            read_data = mem_data_out;                                // LW
            mem_data_in  <= i_mem_data;                              // SW
        end
        3'b100: begin
            read_data = {24'h000000, mem_data_out[7:0]};             // LBU
            mem_data_in <= i_mem_data;                               // SW
        end
        3'b101: begin
            read_data = {16'h0000, mem_data_out[15:0]};             // LHU
            mem_data_in <= i_mem_data;                              // SW
        end     
        default: begin
            read_data = mem_data_out[31:0];
            mem_data_in <= i_mem_data;                              // SW
        end
    endcase 

end

assign data_to_mem = mem_data_in;
assign o_read_data = read_data;

endmodule

