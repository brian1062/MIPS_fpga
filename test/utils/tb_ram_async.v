`timescale 1ns / 1ps

module tb_ram_async_single_port;

    // Parámetros de la memoria
    parameter NB_WIDTH = 32;
    parameter NB_ADDR  = 9;
    parameter NB_DATA  = 8;

    // Entradas y salidas para el DUT
    reg                   i_clk;
    reg                   i_reset;
    reg                   i_we;
    reg [NB_ADDR-1:0]     i_addr;
    reg [NB_WIDTH-1:0]    i_data_in;
    wire [NB_WIDTH-1:0]   o_data_out;

    // Instancia del módulo de memoria
    ram_async_single_port #(
        .NB_WIDHT(NB_WIDTH),
        .NB_ADDR(NB_ADDR),
        .NB_DATA(NB_DATA)
    ) dut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_we(i_we),
        .i_addr(i_addr),
        .i_data_in(i_data_in),
        .o_data_out(o_data_out)
    );

    // Generación del reloj (clock) de 10 ns
    always #5 i_clk = ~i_clk;

    // Proceso de simulación
    initial begin
        // Inicialización de señales
        i_clk = 0;
        i_reset = 0;
        i_we = 0;
        i_addr = 0;
        i_data_in = 0;

        // Reset de la memoria
        #10 i_reset = 1;
        #10 i_reset = 0;

        // Escritura de datos en la dirección 4
        #10 i_we = 1;
        i_addr = 4;
        i_data_in = 32'hA1B2C3D4; // Escribe el valor 0xA1B2C3D4 en la dirección 4
        #10 i_we = 0; // Deshabilita la escritura

        // Leer los datos de la dirección 4
        #10 i_addr = 4;
        #10;

        // Verificación de la salida
        if (o_data_out == 32'hA1B2C3D4) begin
            $display("Test de lectura/escritura exitoso. Valor leido: %h", o_data_out);
        end else begin
            $display("Error en test de lectura/escritura. Valor leido: %h, Valor esperado: %h", o_data_out, 32'hA1B2C3D4);
        end

        // Escritura de otro dato en la dirección 8
        #10 i_we = 1;
        i_addr = 8;
        i_data_in = 32'hDEADBEEF; // Escribe el valor 0xDEADBEEF en la dirección 8
        #10 i_we = 0; // Deshabilita la escritura

        // Leer el dato de la dirección 8
        #10 i_addr = 8;
        #10;

        // Verificación de la salida
        if (o_data_out == 32'hDEADBEEF) begin
            $display("Test de lectura/escritura exitoso. Valor leido: %h", o_data_out);
        end else begin
            $display("Error en test de lectura/escritura. Valor leido: %h, Valor esperado: %h", o_data_out, 32'hDEADBEEF);
        end

        // Finalización de la simulación
        #10 $finish;
    end

endmodule
