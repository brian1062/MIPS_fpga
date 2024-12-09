`timescale 1ns/1ps

module tb_ALU;

    // Parámetros
    parameter NB_INPUT = 32;  // Ancho de los datos de entrada y salida
    parameter NB_CONTROL = 6; // Ancho de las señales de control

    // Entradas
    reg [NB_INPUT-1:0] alu_input_A;             // Primer operando
    reg [NB_INPUT-1:0] alu_input_B;             // Segundo operando
    reg [NB_CONTROL-1:0] o_alu_control_signals; // Señales de control

    // Salidas
    wire [NB_INPUT-1:0] o_alu_result;        // Resultado de la operación
    wire               o_alu_condition_zero; // Indicador de si el resultado es cero

    // Instancia de la ALU
    ALU #(
        .NB_INPUT(NB_INPUT),
        .NB_CONTROL(NB_CONTROL)
    ) u_ALU (
        .alu_input_A(alu_input_A),
        .alu_input_B(alu_input_B),
        .o_alu_control_signals(o_alu_control_signals),
        .o_alu_result(o_alu_result),
        .o_alu_condition_zero(o_alu_condition_zero)
    );

    // Estímulos
    initial begin
        $display("Time\tControl\tInput A\t\tInput B\t\tResult\t\tZero");
        $display("----------------------------------------------------------");

        // Caso 1: ADD (Overflow positivo)
        o_alu_control_signals = 6'b100000; // ADD
        alu_input_A = 32'h7FFFFFFF;
        alu_input_B = 32'h00000001;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 2: ADDU con overflow
        o_alu_control_signals = 6'b100001; // ADDU
        alu_input_A = 32'hFFFFFFFF;
        alu_input_B = 32'h00000001;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 3: SUB (Underflow negativo)
        o_alu_control_signals = 6'b100010; // SUB
        alu_input_A = 32'h80000000;
        alu_input_B = 32'h00000001;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 4: SUBU con wrap-around
        o_alu_control_signals = 6'b100011; // SUBU
        alu_input_A = 32'h00000000;
        alu_input_B = 32'h00000001;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 5: AND con todos ceros
        o_alu_control_signals = 6'b100100; // AND
        alu_input_A = 32'h00000000;
        alu_input_B = 32'h00000000;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 6: OR (Patrón alternado)
        o_alu_control_signals = 6'b100101; // OR
        alu_input_A = 32'hAAAAAAAA;
        alu_input_B = 32'h55555555;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 7: XOR con valores iguales
        o_alu_control_signals = 6'b100110; // XOR
        alu_input_A = 32'h12345678;
        alu_input_B = 32'h12345678;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 8: NOR con patrón mixto
        o_alu_control_signals = 6'b100111; // NOR
        alu_input_A = 32'hF0F0F0F0;
        alu_input_B = 32'h0F0F0F0F;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 9: SLL con shift máximo
        o_alu_control_signals = 6'b000000; // SLL
        alu_input_A = 32'hFFFFFFFF;
        alu_input_B = 32'h0000001F;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 10: SRL (Shift lógico a la derecha)
        o_alu_control_signals = 6'b000010; // SRL
        alu_input_A = 32'h80000000;
        alu_input_B = 32'h0000001F;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 11: Caso no implementado
        o_alu_control_signals = 6'b111111; // Código desconocido
        alu_input_A = 32'h12345678;
        alu_input_B = 32'h87654321;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 12: Operaciones con operandos de un bit
        o_alu_control_signals = 6'b100000; // ADD
        alu_input_A = 32'b1; // Operando mínimo positivo
        alu_input_B = 32'b1;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 13: Operaciones con números negativos
        o_alu_control_signals = 6'b100010; // SUB
        alu_input_A = 32'hFFFFFFFE; // -2
        alu_input_B = 32'hFFFFFFFF; // -1
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 14: Valores límite (máximos y mínimos)
        o_alu_control_signals = 6'b100000; // ADD
        alu_input_A = 32'h7FFFFFFF; // Máximo positivo
        alu_input_B = 32'h00000001; // +1
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 15: Desplazamiento más allá del tamaño del operando
        o_alu_control_signals = 6'b000010; // SRL
        alu_input_A = 32'hFFFFFFFF; 
        alu_input_B = 32'h00000020; // Desplazamiento de 32 bits
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 16: Comparaciones inusuales (SLTU)
        o_alu_control_signals = 6'b101011; // SLTU
        alu_input_A = 32'h80000000; // Mínimo negativo en complemento a 2
        alu_input_B = 32'h00000001; // Positivo pequeño
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 17: Operaciones con ceros
        o_alu_control_signals = 6'b100100; // AND
        alu_input_A = 32'h00000000; 
        alu_input_B = 32'hFFFFFFFF; // Todos los bits en 1
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 18: "Zero flag" con resta que da cero
        o_alu_control_signals = 6'b100010; // SUB
        alu_input_A = 32'h00000001;
        alu_input_B = 32'h00000001; // Resultado esperado: 0
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 19: Operación no implementada
        o_alu_control_signals = 6'b111110; // No implementada
        alu_input_A = 32'h12345678;
        alu_input_B = 32'h87654321;
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 20: XOR con entradas complementarias
        o_alu_control_signals = 6'b100110; // XOR
        alu_input_A = 32'h55555555; 
        alu_input_B = 32'hAAAAAAAA; // Complemento
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 21: Overflow en resta
        o_alu_control_signals = 6'b100010; // SUB
        alu_input_A = 32'h80000000; // Número negativo máximo
        alu_input_B = 32'h7FFFFFFF; // Número positivo máximo
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 22: Prueba ADD (con signo)
        o_alu_control_signals = 6'b100000; // ADD
        alu_input_A = 32'd15;  // Operando 1
        alu_input_B = 32'd10;  // Operando 2
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        o_alu_control_signals = 6'b100000; // ADD
        alu_input_A = -32'd15; // Operando 1 negativo
        alu_input_B = 32'd10;  // Operando 2
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 23: Prueba ADDU (sin signo)
        o_alu_control_signals = 6'b100001; // ADDU
        alu_input_A = 32'hFFFFFFF0; // Operando 1 sin signo
        alu_input_B = 32'd20;       // Operando 2
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 24: Prueba SUB (con signo)
        o_alu_control_signals = 6'b100010; // SUB
        alu_input_A = 32'd20;  // Operando 1
        alu_input_B = 32'd15;  // Operando 2
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        o_alu_control_signals = 6'b100010; // SUB
        alu_input_A = 32'd10;  // Operando 1
        alu_input_B = -32'd5;  // Operando 2 negativo
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        // Caso 25: Prueba SUBU (sin signo)
        o_alu_control_signals = 6'b100011; // SUBU
        alu_input_A = 32'd20;        // Operando 1 sin signo
        alu_input_B = 32'd15;        // Operando 2
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);

        o_alu_control_signals = 6'b100011; // SUBU
        alu_input_A = 32'h00000010;  // Operando 1 sin signo
        alu_input_B = 32'hFFFFFFF0; // Operando 2 sin signo
        #10;
        $display("%0dns\t%b\t%h\t%h\t%h\t%b", $time, o_alu_control_signals, alu_input_A, alu_input_B, o_alu_result, o_alu_condition_zero);
        // Fin de la simulación
        $stop;
    end

endmodule