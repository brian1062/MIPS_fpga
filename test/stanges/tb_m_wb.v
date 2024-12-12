`timescale 1ns/1ps

module tb_M_WB;

    // Parameters
    parameter NB_REG = 32;
    parameter NB_CTRL = 4;
    parameter NB_ADDR = 5;

    // Inputs
    reg i_clk;
    reg i_reset;
    reg i_dunit_clk_en;
    reg [NB_REG-1:0] i_pc_eight;
    reg [NB_REG-1:0] i_read_data;
    reg [NB_REG-1:0] i_alu_res_ex_m;
    reg [NB_ADDR-1:0] i_data_addr_ex_m;
    reg [NB_CTRL-1:0] i_control_from_m;

    // Outputs
    wire [NB_REG-1:0] o_pc_eight;
    wire [NB_REG-1:0] o_read_data;
    wire [NB_REG-1:0] o_alu_res_ex_m;
    wire [NB_ADDR-1:0] o_data_addr_ex_m;
    wire [NB_CTRL-1:0] o_control_from_m;

    // Instantiate the Unit Under Test (UUT)
    M_WB #(
        .NB_REG(NB_REG),
        .NB_CTRL(NB_CTRL),
        .NB_ADDR(NB_ADDR)
    ) uut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_dunit_clk_en(i_dunit_clk_en),
        .i_pc_eight(i_pc_eight),
        .i_read_data(i_read_data),
        .i_alu_res_ex_m(i_alu_res_ex_m),
        .i_data_addr_ex_m(i_data_addr_ex_m),
        .i_control_from_m(i_control_from_m),
        .o_pc_eight(o_pc_eight),
        .o_read_data(o_read_data),
        .o_alu_res_ex_m(o_alu_res_ex_m),
        .o_data_addr_ex_m(o_data_addr_ex_m),
        .o_control_from_m(o_control_from_m)
    );

    // Clock generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk; // 10ns clock period
    end

    // Task for checking outputs
    task check_output;
        input [NB_REG-1:0] expected_pc_eight;
        input [NB_REG-1:0] expected_read_data;
        input [NB_REG-1:0] expected_alu_res_ex_m;
        input [NB_ADDR-1:0] expected_data_addr_ex_m;
        input [NB_CTRL-1:0] expected_control_from_m;
        input [8*50:1] test_name; // Array of characters for test name
        begin
            if (o_pc_eight === expected_pc_eight &&
                o_read_data === expected_read_data &&
                o_alu_res_ex_m === expected_alu_res_ex_m &&
                o_data_addr_ex_m === expected_data_addr_ex_m &&
                o_control_from_m === expected_control_from_m) begin
                $display("[PASS] %s", test_name);
            end else begin
                $display("[FAIL] %s | Expected: pc_eight=0x%h, read_data=0x%h, alu_res_ex_m=0x%h, data_addr_ex_m=0x%h, control_from_m=0x%h | Got: pc_eight=0x%h, read_data=0x%h, alu_res_ex_m=0x%h, data_addr_ex_m=0x%h, control_from_m=0x%h",
                          test_name, expected_pc_eight, expected_read_data, expected_alu_res_ex_m, expected_data_addr_ex_m, expected_control_from_m,
                          o_pc_eight, o_read_data, o_alu_res_ex_m, o_data_addr_ex_m, o_control_from_m);
            end
        end
    endtask

    // Testbench logic
    initial begin
        // Initialize inputs
        i_reset = 1;
        i_dunit_clk_en = 0;
        i_pc_eight = 32'h00000000;
        i_read_data = 32'h00000000;
        i_alu_res_ex_m = 32'h00000000;
        i_data_addr_ex_m = 5'h00;
        i_control_from_m = 4'h0;

        // Wait for the clock to stabilize
        #20;

        // Test reset functionality
        i_reset = 1;
        #10;
        check_output(32'h00000000, 32'h00000000, 32'h00000000, 5'h00, 4'h0, "Test Reset");
        i_reset = 0;

        // Test write functionality
        i_dunit_clk_en = 1;
        i_pc_eight = 32'hAAAA_AAAA;
        i_read_data = 32'hBBBB_BBBB;
        i_alu_res_ex_m = 32'hCCCC_CCCC;
        i_data_addr_ex_m = 5'h1F;
        i_control_from_m = 4'hF;
        #10;
        check_output(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 5'h1F, 4'hF, "Test Write");

        // Test stall (i_dunit_clk_en = 0)
        i_dunit_clk_en = 0;
        i_pc_eight = 32'h1111_1111;
        i_read_data = 32'h2222_2222;
        i_alu_res_ex_m = 32'h3333_3333;
        i_data_addr_ex_m = 5'h10;
        i_control_from_m = 4'hA;
        #10;
        check_output(32'hAAAA_AAAA, 32'hBBBB_BBBB, 32'hCCCC_CCCC, 5'h1F, 4'hF, "Test Stall");

        // End simulation
        $stop;
    end

endmodule
