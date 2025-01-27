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
    reg [NB_WIDHT-1:0]    i_dunit_addr;
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
        .i_dunit_addr(i_dunit_addr),
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
        i_dunit_addr     = 0;
        i_dunit_data_if   = 0;

        // Wait for a few cycles
        #15;
        i_reset = 0;  // Release reset
        i_dunit_reset_pc = 1;
        i_dunit_clk_en = 1;
        i_dunit_w_en=1;
        // ----------- Operaciones -----------

        // 1. ADDI: Guardar 1 en $1 de la memoria de registros
        i_dunit_addr = 32'h0000_0004; 
        i_dunit_data_if = 32'b001000_00000_00001_00000_00000_000001; // ADDI $1, $0, 1
        // Acción esperada: $1 = 1
        #10;

        // 2. ADDI: Guardar 2 en $2 de la memoria de registros
        i_dunit_addr = 32'h0000_0008;
        i_dunit_data_if = 32'b001000_00000_00010_00000_00000_000010; // ADDI $2, $0, 2
        // Acción esperada: $2 = 2
        #10;

        // SW: Guardar el contenido de $2 (valor: 2) en la posición 4 de la memoria de datos
        i_dunit_addr = 32'h0000_0012;
        i_dunit_data_if = 32'b101011_00000_00010_00000_00000_000100; // SW $2, 4($0)
        // Acción esperada: El valor 2 de $2 se almacena en la dirección 4 de la memoria de datos.
        #10;

        // LW: Cargar el contenido de la dirección 4 de la memoria de datos en $17
        i_dunit_addr = 32'h0000_0016;
        i_dunit_data_if = 32'b100011_00000_10001_00000_00000_000100; // LW $17, 4($0)
        // Resultado esperado: $17 = 2 (cargado desde la dirección 4 de la memoria de datos)
        #10;

        // SW: Guardar el contenido de $1 (valor: 1) en la posición 8 de la memoria de datos
        i_dunit_addr = 32'h0000_0020;
        i_dunit_data_if = 32'b101011_00000_00001_00000_00000_001000; // SW $1, 8($0)
        // Acción esperada: El valor 1 de $1 se almacena en la dirección 8 de la memoria de datos.
        #10;

        // LW: Cargar el contenido de la dirección 8 de la memoria de datos en $18
        i_dunit_addr = 32'h0000_0024;
        i_dunit_data_if = 32'b100011_00000_10010_00000_00000_001000; // LW $18, 8($0)
        // Resultado esperado: $18 = 1 (cargado desde la dirección 8 de la memoria de datos)

        i_dunit_w_en = 0;
        i_dunit_reset_pc = 0;
        #10;
        //comparar
        #10; 

        i_dunit_addr=4;
        #10
        i_dunit_addr=8;
        #10

        // End simulation
        #500;
        $stop;
    end
endmodule