`timescale 1ns/1ps

module tb_ID_EX;

    // Parameters
    parameter NB_REG = 32;
    parameter NB_CTRL = 18;

    // Inputs
    reg i_clk;
    reg i_reset;
    reg i_dunit_clk_en;
    reg [NB_REG-1:0] i_pc_eight;
    reg [NB_REG-1:0] i_rs_data;
    reg [NB_REG-1:0] i_rt_data;
    reg signed [NB_REG-1:0] i_sign_extension;
    reg [NB_CTRL-1:0] i_control_unit;

    // Outputs
    wire [NB_REG-1:0] o_pc_eight;
    wire [NB_REG-1:0] o_rs_data;
    wire [NB_REG-1:0] o_rt_data;
    wire signed [NB_REG-1:0] o_sign_extension;
    wire [NB_CTRL-1:0] o_control_unit;

    // Instantiate the Unit Under Test (UUT)
    ID_EX #(
        .NB_REG(NB_REG),
        .NB_CTRL(NB_CTRL)
    ) uut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_dunit_clk_en(i_dunit_clk_en),
        .i_pc_eight(i_pc_eight),
        .i_rs_data(i_rs_data),
        .i_rt_data(i_rt_data),
        .i_sign_extension(i_sign_extension),
        .i_control_unit(i_control_unit),
        .o_pc_eight(o_pc_eight),
        .o_rs_data(o_rs_data),
        .o_rt_data(o_rt_data),
        .o_sign_extension(o_sign_extension),
        .o_control_unit(o_control_unit)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 10ns clock period
    end

    // Task for checking outputs
    task check_output;
        input [NB_REG-1:0] expected_pc_eight;
        input [NB_REG-1:0] expected_rs_data;
        input [NB_REG-1:0] expected_rt_data;
        input signed [NB_REG-1:0] expected_sign_extension;
        input [NB_CTRL-1:0] expected_control_unit;
        input [8*50:1] test_name; // Array of characters for test name
        begin
            if (o_pc_eight === expected_pc_eight &&
                o_rs_data === expected_rs_data &&
                o_rt_data === expected_rt_data &&
                o_sign_extension === expected_sign_extension &&
                o_control_unit === expected_control_unit) begin
                $display("[PASS] %s", test_name);
            end else begin
                $display("[FAIL] %s | Expected: pc_eight=0x%h, rs_data=0x%h, rt_data=0x%h, sign_extension=0x%h, control_unit=0x%h | Got: pc_eight=0x%h, rs_data=0x%h, rt_data=0x%h, sign_extension=0x%h, control_unit=0x%h",
                          test_name, expected_pc_eight, expected_rs_data, expected_rt_data, expected_sign_extension, expected_control_unit,
                          o_pc_eight, o_rs_data, o_rt_data, o_sign_extension, o_control_unit);
            end
        end
    endtask

    // Testbench logic
    initial begin
        // Initialize inputs
        i_reset = 1;
        i_dunit_clk_en = 0;
        i_pc_eight = 32'h00000000;
        i_rs_data = 32'h00000000;
        i_rt_data = 32'h00000000;
        i_sign_extension = 32'sh00000000;
        i_control_unit = 18'h00000;

        // Wait for the clock to stabilize
        #20;

        // Test reset functionality
        i_reset = 1;
        #10;
        check_output(32'h00000000, 32'h00000000, 32'h00000000, 32'sh00000000, 18'h00000, "Test Reset");
        i_reset = 0;

        // Test write functionality
        i_dunit_clk_en = 1;
        i_pc_eight = 32'hAAAA_AAAA;
        i_rs_data = 32'hBBBB_BBBB;
        i_rt_data = 32'hCCCC_CCCC;
        i_sign_extension = 32'sh1234_5678;
        i_control_unit = 18'h3FFFF;
        #10;
        check_output(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 32'sh1234_5678, 18'h3FFFF, "Test Write");

        // Test stall (i_dunit_clk_en = 0)
        i_dunit_clk_en = 0;
        i_pc_eight = 32'h1111_1111;
        i_rs_data = 32'h2222_2222;
        i_rt_data = 32'h3333_3333;
        i_sign_extension = 32'sh4444_4444;
        i_control_unit = 18'h0F0F0;
        #10;
        check_output(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 32'sh1234_5678, 18'h3FFFF, "Test Stall");

        // End simulation
        $stop;
    end

endmodule
