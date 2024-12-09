`timescale 1ns/1ps

module tb_MEM;

/////////////////////////////////////////////////////////////
// Parameters
/////////////////////////////////////////////////////////////
localparam NB_WIDTH = 32; // Data width
localparam NB_ADDR  = 9;  // Address width
localparam NB_DATA  = 8;  // Memory element width

/////////////////////////////////////////////////////////////
// Signals
/////////////////////////////////////////////////////////////
reg                   clk;
reg                   reset;
reg  [NB_WIDTH-1:0]   mem_addr;
reg  [NB_WIDTH-1:0]   mem_data;
reg                   mem_read_CU;
reg                   mem_write_CU;
reg  [2:0]            BHW_CU;
wire [NB_WIDTH-1:0]   read_data;

/////////////////////////////////////////////////////////////
// Module Under Test (MUT)
/////////////////////////////////////////////////////////////
MEM #(
    .NB_WIDTH(NB_WIDTH),
    .NB_ADDR (NB_ADDR),
    .NB_DATA (NB_DATA)
) uut (
    .i_clk          (clk),
    .i_reset        (reset),
    .i_mem_addr     (mem_addr),
    .i_mem_data     (mem_data),
    .i_mem_read_CU  (mem_read_CU),
    .i_mem_write_CU (mem_write_CU),
    .i_BHW_CU       (BHW_CU),
    .o_read_data    (read_data)
);

/////////////////////////////////////////////////////////////
// Clock Generation
/////////////////////////////////////////////////////////////
always #5 clk = ~clk; // 10ns clock period

/////////////////////////////////////////////////////////////
// Test Bench Logic
/////////////////////////////////////////////////////////////
initial begin
    // Initialize signals
    clk         = 0;
    reset       = 1;
    mem_addr    = 0;
    mem_data    = 0;
    mem_read_CU = 0;
    mem_write_CU = 0;
    BHW_CU      = 0;

    // Reset the module
    #10 reset = 0;

    // Test Case: Write and Read Operations
    // -----------------------------------------------------

    // Test 1: Store Word (SW)
    @(posedge clk);
    mem_addr    = 9'h010; // Address 0x10
    mem_data    = 32'h12345678;
    mem_write_CU = 1;
    BHW_CU      = 3'b011; // SW
    @(posedge clk);
    mem_write_CU = 0;

    // Test 2: Load Word (LW) - Lectura en el flanco negativo
    @(posedge clk); // Lectura en el flanco negativo
    mem_read_CU = 1;
    BHW_CU      = 3'b011; // LW
    @(posedge clk); // Lectura completada
    mem_read_CU = 0;
    if (read_data !== 32'h12345678)
        $display("Test LW Failed: Expected 0x12345678, Got 0x%h", read_data);
    else
        $display("Test LW Passed: Read 0x%h", read_data);

    // Test 3: Load Word Unsigned (LWU)
    @(posedge clk);
    mem_read_CU = 1;
    BHW_CU      = 3'b111; // SLWU
    @(posedge clk);
    mem_read_CU = 0;
    if (read_data !== 32'h12345678)
        $display("Test LWU Failed: Expected 0x12345678, Got 0x%h", read_data);
    else
        $display("Test LWU Passed: Read 0x%h", read_data);

    // Test 4: Store Byte (SB)
    @(posedge clk);
    mem_addr    = 9'h011; // Address 0x11
    mem_data    = 32'h000000AB; // Write 0xAB to byte
    mem_write_CU = 1;
    BHW_CU      = 3'b000; // SB
    @(posedge clk);
    mem_write_CU = 0;

    // Test 5: Load Byte (LB)
    @(posedge clk);
    mem_read_CU = 1;
    BHW_CU      = 3'b000; // LB
    @(posedge clk);
    mem_read_CU = 0;
    if (read_data[7:0] !== 8'hAB)
        $display("Test LB Failed: Expected 0xAB, Got 0x%h", read_data[7:0]);
    else
        $display("Test LB Passed: Read 0x%h", read_data[7:0]);

    // Test 6: Load Byte Unsigned (LBU)
    @(posedge clk);
    mem_read_CU = 1;
    BHW_CU      = 3'b100; // LBU
    @(posedge clk);
    mem_read_CU = 0;
    if (read_data[7:0] !== 8'hAB)
        $display("Test LBU Failed: Expected 0xAB, Got 0x%h", read_data[7:0]);
    else
        $display("Test LBU Passed: Read 0x%h", read_data[7:0]);

    // Test 7: Store Halfword (SH)
    @(posedge clk);
    mem_addr    = 9'h012; // Address 0x12
    mem_data    = 32'h0000CDEF; // Write 0xCDEF
    mem_write_CU = 1;
    BHW_CU      = 3'b001; // SH
    @(posedge clk);
    mem_write_CU = 0;

    // Test 8: Load Halfword (LH)
    @(posedge clk);
    mem_read_CU = 1;
    BHW_CU      = 3'b001; // LH
    @(posedge clk);
    mem_read_CU = 0;
    if (read_data[15:0] !== 16'hCDEF)
        $display("Test LH Failed: Expected 0xCDEF, Got 0x%h", read_data[15:0]);
    else
        $display("Test LH Passed: Read 0x%h", read_data[15:0]);

    // Test 9: Load Halfword Unsigned (LHU)
    @(posedge clk);
    mem_read_CU = 1;
    BHW_CU      = 3'b101; // LHU
    @(posedge clk);
    mem_read_CU = 0;
    if (read_data[15:0] !== 16'hCDEF)
        $display("Test LHU Failed: Expected 0xCDEF, Got 0x%h", read_data[15:0]);
    else
        $display("Test LHU Passed: Read 0x%h", read_data[15:0]);

    // Test 10: Write at lowest address (0x000)
    @(posedge clk);
    mem_addr    = 9'h000; // Address 0x000
    mem_data    = 32'h00000001; // Write data
    mem_write_CU = 1;
    BHW_CU      = 3'b011; // SW
    @(posedge clk);
    mem_write_CU = 0;

    // Test 11: Read from lowest address (0x000)
    @(posedge clk); // Lectura en flanco negativo
    mem_read_CU = 1;
    BHW_CU      = 3'b011; // LW
    @(posedge clk);
    mem_read_CU = 0;
    if (read_data !== 32'h00000001)
        $display("Test Read Lowest Address Failed: Expected 0x00000001, Got 0x%h", read_data);
    else
        $display("Test Read Lowest Address Passed: Read 0x%h", read_data);

    ///////////////////////////////////////////////////////////////
    $finish;
end

endmodule
