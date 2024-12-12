`timescale 1ns/1ps

module tb_EX_M;

    // Parameters
    parameter NB_REG = 32;
    parameter NB_CTRL = 9;
    parameter NB_ADDR = 5;

    // Inputs
    reg i_clk;
    reg i_reset;
    reg i_dunit_clk_en;
    reg [NB_REG-1:0] i_pc_eight;
    reg [NB_REG-1:0] i_alu_result;
    reg [NB_REG-1:0] i_w_data;
    reg [NB_ADDR-1:0] i_data_addr;
    reg [NB_CTRL-1:0] i_control_from_ex;

    // Outputs
    wire [NB_REG-1:0] o_pc_eight;
    wire [NB_REG-1:0] o_alu_result;
    wire [NB_REG-1:0] o_w_data;
    wire [NB_ADDR-1:0] o_data_addr;
    wire [NB_CTRL-1:0] o_control_from_ex;

    // Instantiate the Unit Under Test (UUT)
    EX_M #(
        .NB_REG(NB_REG),
        .NB_CTRL(NB_CTRL),
        .NB_ADDR(NB_ADDR)
    ) uut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_dunit_clk_en(i_dunit_clk_en),
        .i_pc_eight(i_pc_eight),
        .i_alu_result(i_alu_result),
        .i_w_data(i_w_data),
        .i_data_addr(i_data_addr),
        .i_control_from_ex(i_control_from_ex),
        .o_pc_eight(o_pc_eight),
        .o_alu_result(o_alu_result),
        .o_w_data(o_w_data),
        .o_data_addr(o_data_addr),
        .o_control_from_ex(o_control_from_ex)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 10ns clock period
    end

    // Task for checking outputs
    task check_output;
        input [NB_REG-1:0] expected_pc_eight;
        input [NB_REG-1:0] expected_alu_result;
        input [NB_REG-1:0] expected_w_data;
        input [NB_ADDR-1:0] expected_data_addr;
        input [NB_CTRL-1:0] expected_control_from_ex;
        input [8*50:1] test_name; // Array of characters for test name
        begin
            if (o_pc_eight === expected_pc_eight &&
                o_alu_result === expected_alu_result &&
                o_w_data === expected_w_data &&
                o_data_addr === expected_data_addr &&
                o_control_from_ex === expected_control_from_ex) begin
                $display("[PASS] %s", test_name);
            end else begin
                $display("[FAIL] %s | Expected: pc_eight=0x%h, alu_result=0x%h, w_data=0x%h, data_addr=0x%h, control_from_ex=0x%h | Got: pc_eight=0x%h, alu_result=0x%h, w_data=0x%h, data_addr=0x%h, control_from_ex=0x%h",
                          test_name, expected_pc_eight, expected_alu_result, expected_w_data, expected_data_addr, expected_control_from_ex,
                          o_pc_eight, o_alu_result, o_w_data, o_data_addr, o_control_from_ex);
            end
        end
    endtask

    // Testbench logic
    initial begin
        // Initialize inputs
        i_reset = 1;
        i_dunit_clk_en = 0;
        i_pc_eight = 32'hAAAA_AAAA;
        i_alu_result = 32'h00000000;
        i_w_data = 32'h00000000;
        i_data_addr = 5'h00;
        i_control_from_ex = 9'h000;

        // Wait for the clock to stabilize
        #20;

        // Test reset functionality
        i_reset = 1;
        #10;
        check_output(32'h00000000, 32'h00000000, 32'h00000000, 5'h00, 9'h000, "Test Reset");
        i_reset = 0;

        // Test write functionality
        i_dunit_clk_en = 1;
        i_pc_eight = 32'hAAAA_AAAA;
        i_alu_result = 32'hBBBB_BBBB;
        i_w_data = 32'hCCCC_CCCC;
        i_data_addr = 5'h1F;
        i_control_from_ex = 9'h1FF;
        #10;
        check_output(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 5'h1F, 9'h1FF, "Test Write");

        // Test stall (i_dunit_clk_en = 0)
        i_dunit_clk_en = 0;
        i_pc_eight = 32'h1111_1111;
        i_alu_result = 32'h2222_2222;
        i_w_data = 32'h3333_3333;
        i_data_addr = 5'h10;
        i_control_from_ex = 9'h0AA;
        #10;
        check_output(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 5'h1F, 9'h1FF, "Test Stall");

        // End simulation
        $stop;
    end

endmodule
