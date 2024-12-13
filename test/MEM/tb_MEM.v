`timescale 1ns / 1ps

module tb_MEM;

    // Parámetros de la memoria
    parameter NB_WIDTH = 32;
    parameter NB_ADDR  = 9;
    parameter NB_DATA  = 8;

    // Entradas y salidas para el DUT
    reg                   i_clk;
    reg                   i_reset;
    reg [NB_WIDTH-1:0]    i_mem_addr;
    reg [NB_WIDTH-1:0]    i_mem_data;
    reg                   i_mem_read_CU;
    reg                   i_mem_write_CU;
    reg [2:0]             i_BHW_CU;
    wire [NB_WIDTH-1:0]   o_read_data;

    // Instancia del módulo MEM
    MEM #(
        .NB_WIDTH(NB_WIDTH),
        .NB_ADDR(NB_ADDR),
        .NB_DATA(NB_DATA)
    ) dut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_mem_addr(i_mem_addr),
        .i_mem_data(i_mem_data),
        .i_mem_read_CU(i_mem_read_CU),
        .i_mem_write_CU(i_mem_write_CU),
        .i_BHW_CU(i_BHW_CU),
        .o_read_data(o_read_data)
    );

    // Generación del reloj (clock) de 10 ns
    always #5 i_clk = ~i_clk;

    // Proceso de simulación
    initial begin
        // Inicialización de señales
        i_clk = 0;
        i_reset = 0;
        i_mem_addr = 0;
        i_mem_data = 0;
        i_mem_read_CU = 0;
        i_mem_write_CU = 0;
        i_BHW_CU = 3'b000;

        // Reset de la memoria
        #10 i_reset = 1;
        #10 i_reset = 0;

        // Escribir datos con diferentes operaciones
        // SB (escritura de 1 byte)
        #10 i_mem_write_CU = 1;
        i_mem_addr = 4;
        i_mem_data = 32'h000000FF; // Escribe 0xFF en la dirección 4
        i_BHW_CU = 3'b000; // SB
        #10 i_mem_write_CU = 0;

        // Verificación de la lectura de SB
        #10 i_mem_read_CU = 1;
        i_mem_addr = 4;
        i_BHW_CU = 3'b000; // LB
        #10 i_mem_read_CU = 0;
        if (o_read_data == 32'hFFFFFFFF) begin
            $display("Test de SB y LB exitoso. Valor leido: %h", o_read_data);
        end else begin
            $display("Error en test de SB y LB. Valor leido: %h", o_read_data);
        end

        // SH (escritura de 2 bytes)
        #10 i_mem_write_CU = 1;
        i_mem_addr = 8;
        i_mem_data = 32'h0000A5A5; // Escribe 0xA5A5 en la dirección 8
        i_BHW_CU = 3'b001; // SH
        #10 i_mem_write_CU = 0;

        // Verificación de la lectura de SH
        #10 i_mem_read_CU = 1;
        i_mem_addr = 8;
        i_BHW_CU = 3'b001; // LH
        #10 i_mem_read_CU = 0;
        if (o_read_data == 32'hFFFFA5A5) begin
            $display("Test de SH y LH exitoso. Valor leido: %h", o_read_data);
        end else begin
            $display("Error en test de SH y LH. Valor leido: %h", o_read_data);
        end

        // SW (escritura de 4 bytes)
        #10 i_mem_write_CU = 1;
        i_mem_addr = 12;
        i_mem_data = 32'hDEADBEEF; // Escribe 0xDEADBEEF en la dirección 12
        i_BHW_CU = 3'b011; // SW
        #10 i_mem_write_CU = 0;

        // Verificación de la lectura de SW
        #10 i_mem_read_CU = 1;
        i_mem_addr = 12;
        i_BHW_CU = 3'b011; // LW
        #10 i_mem_read_CU = 0;
        if (o_read_data == 32'hDEADBEEF) begin
            $display("Test de SW y LW exitoso. Valor leido: %h", o_read_data);
        end else begin
            $display("Error en test de SW y LW. Valor leido: %h", o_read_data);
        end

        // LBU (lectura de byte sin signo)
        #10 i_mem_addr = 16;
        i_mem_data = 32'h0F0000FF; // Escribe 0xFF en la dirección 16
        i_mem_write_CU = 1;
        i_BHW_CU = 3'b100; // SB
        #10 i_mem_write_CU = 0;

        // Verificación de LBU
        #10 i_mem_read_CU = 1;
        i_mem_addr = 16;
        i_BHW_CU = 3'b100; // LBU
        #10 i_mem_read_CU = 0;
        if (o_read_data == 32'h000000FF) begin
            $display("Test de LBU exitoso. Valor leido: %h", o_read_data);
        end else begin
            $display("Error en test de LBU. Valor leido: %h", o_read_data);
        end

        // LHU (lectura de halfword sin signo)
        #10 i_mem_addr = 20;
        i_mem_data = 32'h0000FF00; // Escribe 0xFF00 en la dirección 20
        i_mem_write_CU = 1;
        i_BHW_CU = 3'b101; // SH
        #10 i_mem_write_CU = 0;

        // Verificación de LHU
        #10 i_mem_read_CU = 1;
        i_mem_addr = 20;
        i_BHW_CU = 3'b101; // LHU
        #10 i_mem_read_CU = 0;
        if (o_read_data == 32'h0000FF00) begin
            $display("Test de LHU exitoso. Valor leido: %h", o_read_data);
        end else begin
            $display("Error en test de LHU. Valor leido: %h", o_read_data);
        end

        // Finalización de la simulación
        #10 $finish;
    end

endmodule
