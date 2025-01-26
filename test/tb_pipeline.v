module tb_pipeline;

    // Parameters
    parameter NB_REG   = 32;
    parameter NB_WIDHT = 9;
    parameter NB_OP    = 6;
    parameter NB_ADDR  = 5;

    // Testbench Signals
    reg                   i_clk;
    reg                   i_reset;
    reg                   i_dunit_clk_en;
    reg                   i_dunit_reset_pc;
    reg                   i_dunit_w_en;
    reg                   i_dunit_r_data;
    reg [NB_WIDHT-1:0]    i_dunit_addr_data;
    reg [NB_ADDR-1:0]     i_dunit_addr;
    reg [NB_REG-1:0]      i_dunit_mem_addr;
    reg [NB_REG-1:0]      i_dunit_data_if;
    wire [NB_REG-1:0]     o_dunit_mem_data;
    wire [NB_REG-1:0]     o_dunit_reg;

    // Clock Generation
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;  // 10 ns clock period
        forever #5 i_dunit_clk_en = ~i_dunit_clk_en;  // 10 ns clock period
    end

    // DUT (Device Under Test)
    pipeline #(
        .NB_REG(NB_REG),
        .NB_WIDHT(NB_WIDHT),
        .NB_OP(NB_OP),
        .NB_ADDR(NB_ADDR)
    ) uut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_dunit_clk_en(i_dunit_clk_en),
        .i_dunit_reset_pc(i_dunit_reset_pc),
        .i_dunit_w_mem(i_dunit_w_en),
        .i_dunit_addr(i_dunit_addr_data),
        .i_dunit_data_if(i_dunit_data_if),
        .o_dunit_reg(o_dunit_reg),
        .o_dunit_mem_data(o_dunit_mem_data)
    );

    // Test Scenarios
    initial begin
        // Initialize inputs
        i_reset          = 1;
        i_dunit_clk_en   = 0;
        i_dunit_reset_pc = 0;
        i_dunit_w_en     = 0;
        i_dunit_r_data   = 0;
        i_dunit_addr_data = 0;
        i_dunit_addr      = 0;
        i_dunit_mem_addr  = 0;
        i_dunit_data_if   = 0;

        // Wait for a few cycles
        #15;
        i_reset = 0;  // Release reset
        i_dunit_reset_pc = 1;
        i_dunit_clk_en = 1;
        i_dunit_w_en=1;
        // ----------- Operaciones -----------

        // Instructions
        // 1. ADDI: Guardar 1 en $1
        i_dunit_mem_addr = 32'h0000_0004; 
        i_dunit_data_if = 32'b001000_00000_00001_00000_00000_000001; // ADDI $1, $0, 1
        #10;

        // 2. SW: Guardar el valor de $1 en la posición 4 de memoria
        i_dunit_mem_addr = 32'h0000_0008; 
        i_dunit_data_if = 32'b101011_00000_00001_00000_00000_000100; // SW $1, 4($0)
        #10;

        // 3. LW: Cargar el valor de la posición 4 de memoria en $2
        i_dunit_mem_addr = 32'h0000_000C; 
        i_dunit_data_if = 32'b100011_00000_00010_00000_00000_000100; // LW $2, 4($0)
        #10;

        // 4. ADDU: Sumar $1 y $2 y guardar el resultado en $3
        i_dunit_mem_addr = 32'h0000_0010; 
        i_dunit_data_if = 32'b000000_00001_00010_00011_00000_100001; // ADDU $3, $1, $2
        #10;

        // 5. SW: Guardar el valor de $3 en la posición 8 de memoria
        i_dunit_mem_addr = 32'h0000_0014; 
        i_dunit_data_if = 32'b101011_00000_00011_00000_00000_001000; // SW $3, 8($0)
        #10;


        // 6. SUBU: Restar $1 y $2 y guardar el resultado en $4
        i_dunit_mem_addr = 32'h0000_0018; 
        i_dunit_data_if = 32'b000000_00001_00010_00100_00000_100011; // SUBU $4, $1, $2
        #10;

        // 7. SW: Guardar el valor de $4 en la posición 12 de memoria
        i_dunit_mem_addr = 32'h0000_001C; 
        i_dunit_data_if = 32'b101011_00100_00000_00000_00000_001100; // SW $4, 12($0)
        #10;

        i_dunit_w_en = 0;
        i_dunit_reset_pc = 0;
        #10;
        //comparar
        #10; 

        // End simulation
        #500;
        $stop;
    end
endmodule