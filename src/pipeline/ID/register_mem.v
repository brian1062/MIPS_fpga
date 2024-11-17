
/////////////////////////////////////////////////////////////
// Module: register_mem
// Description: Register file implementation for a pipelined processor.
//              Supports reading two registers and writing one register 
//              in a single clock cycle. Includes reset functionality
//              to clear all registers.
// Author: Brian Gerard
// Created: 13/11/2024
// Parameters:
//   - NB_REG: Bit-width of each register (default: 32).
//   - NB_ADDR: Bit-width of the address to index registers (default: 5).
// Inputs:
//   - i_clk: Clock signal.
//   - i_reset: Reset signal to clear all registers.
//   - i_enable: Enable signal for write operations.
//   - i_dunit_clk_en: Additional clock enable for write operations.
//   - i_rs_addr: Address of the first register to read.
//   - i_rt_addr: Address of the second register to read.
//   - i_wb_addr: Address of the register to write to.
//   - i_wb_data: Data to write into the specified register.
// Outputs:
//   - o_rs_data: Data read from the first register.
//   - o_rt_data: Data read from the second register.
/////////////////////////////////////////////////////////////

module register_mem 
#(
    parameter NB_REG  = 32,  // Width of each register.
    parameter NB_ADDR =  5   // Number of bits for register addressing.
) (
    input                       i_clk           , // Clock signal.
    input                       i_reset         , // Reset signal.
    input                       i_enable        , // Write enable signal.
    input                       i_dunit_clk_en  , // Additional clock enable for data unit.
    input   [NB_ADDR - 1 : 0]   i_rs_addr       , // Address of the first register to read.
    input   [NB_ADDR - 1 : 0]   i_rt_addr       , // Address of the second register to read.
    input   [NB_ADDR - 1 : 0]   i_wb_addr       , // Address of the register to write to.
    input   [NB_REG  - 1 : 0]   i_wb_data       , // Data to write into the specified register.
    output  [NB_REG  - 1 : 0]   o_rs_data       , // Data read from the first register.
    output  [NB_REG  - 1 : 0]   o_rt_data         // Data read from the second register.
);

/////////////////////////////////////////////////////////////
// Internal Register Memory
// Implements a memory array for storing registers.
/////////////////////////////////////////////////////////////
reg [NB_REG-1:0] reg_mem [2**NB_ADDR-1:0];

// Write to register memory on the negative edge of the clock.
integer i;
always @(negedge i_clk) begin
    if (i_reset) begin
        // Clear all registers during reset.
        for (i = 0; i < 2**NB_ADDR; i = i + 1) begin
            reg_mem[i] <= 0;
        end        
    end
    else if (i_enable & i_dunit_clk_en) begin
        reg_mem[i_wb_addr] <= i_wb_data;
    end

end


/////////////////////////////////////////////////////////////
// Read Logic
// Read the contents of the specified registers.
/////////////////////////////////////////////////////////////
assign o_rs_data = reg_mem[i_rs_addr]; // Output data from the first register.
assign o_rt_data = reg_mem[i_rt_addr]; // Output data from the second register.
   
endmodule