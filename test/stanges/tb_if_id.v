`timescale 1ns/1ps

module tb_if_id;

    // Parameters
    parameter NB_REG = 32;

    // Inputs
    reg i_clk;
    reg i_reset;
    reg i_dunit_clk_en;
    reg [NB_REG-1:0] i_pc_four;
    reg [NB_REG-1:0] i_data_ins_mem;
    reg i_flush;
    reg i_write;

    // Outputs
    wire [NB_REG-1:0] o_pc_four;
    wire [NB_REG-1:0] o_data_ins_mem;

    // Instantiate the Unit Under Test (UUT)
    IF_ID #(
        .NB_REG(NB_REG)
    ) uut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_dunit_clk_en(i_dunit_clk_en),
        .i_pc_four(i_pc_four),
        .i_data_ins_mem(i_data_ins_mem),
        .i_flush(i_flush),
        .i_write(i_write),
        .o_pc_four(o_pc_four),
        .o_data_ins_mem(o_data_ins_mem)
    );

    // Clock generation
    always #5 i_clk = ~i_clk;

    // Task for checking outputs
    task check_output;
        input [NB_REG-1:0] expected_pc_four;
        input [NB_REG-1:0] expected_data_ins_mem;
        input [8*50:1] test_name;
        begin
            if (o_pc_four === expected_pc_four && o_data_ins_mem === expected_data_ins_mem) begin
                $display("[PASS] %s", test_name);
            end else begin
                $display("[FAIL] %s | Expected: pc_four=0x%h, data_ins_mem=0x%h | Got: pc_four=0x%h, data_ins_mem=0x%h", 
                          test_name, expected_pc_four, expected_data_ins_mem, o_pc_four, o_data_ins_mem);
            end
        end
    endtask

    // Testbench logic
    initial begin
        // Initialize inputs
        i_clk=0;
        i_reset = 1;
        i_dunit_clk_en = 0;
        i_pc_four = 32'h00000000;
        i_data_ins_mem = 32'h00000000;
        i_flush = 0;
        i_write = 0;

        // Wait for the clock to stabilize
        #20;

        // Test reset functionality
        i_reset = 1;
        #10;
        check_output(32'h00000000, 32'h00000000, "Test Reset");
        i_reset = 0;

        // Test write functionality
        i_dunit_clk_en = 1;
        i_write = 1;
        i_pc_four = 32'hAAAA_AAAA;
        i_data_ins_mem = 32'hBBBB_BBBB;
        #10;
        check_output(32'hAAAA_AAAA, 32'hBBBB_BBBB, "Test Write");

        // Test stall (i_write = 0)
        i_write = 0;
        i_pc_four = 32'hCCCC_CCCC;
        i_data_ins_mem = 32'hDDDD_DDDD;
        #10;
        check_output(32'hAAAA_AAAA, 32'hBBBB_BBBB, "Test Stall");

        // Test flush functionality
        i_flush = 1;
        #10;
        check_output(32'h00000000, 32'h00000000, "Test Flush");
        i_flush = 0;

        // Test normal operation after flush
        i_write = 1;
        i_pc_four = 32'h1234_5678;
        i_data_ins_mem = 32'h8765_4321;
        #10;
        check_output(32'h1234_5678, 32'h8765_4321, "Test Normal Operation After Flush");

        // End simulation
        $stop;
    end

endmodule
