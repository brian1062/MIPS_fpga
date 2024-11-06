`timescale 1ns / 1ps

module tb_adder_four;
    reg [31:0] a_input;       // Registro para la entrada a_input
    wire [31:0] sum;          // Cable para la salida sum

    // Instancia del módulo adder_four
    adder_four #(.ADDER_WIDTH(32)) adder (
        .a_input(a_input),
        .sum(sum)
    );

    initial begin
        a_input = 32'd0; #10;
        if (sum == 32'd4)
            $display("Prueba 1 pasada: a_input = %d, sum = %d (Esperado: 4)", a_input, sum);
        else
            $display("Prueba 1 fallida: a_input = %d, sum = %d (Esperado: 4)", a_input, sum);

        a_input = 32'd10; #10;
        if (sum == 32'd14)
            $display("Prueba 2 pasada: a_input = %d, sum = %d (Esperado: 14)", a_input, sum);
        else
            $display("Prueba 2 fallida: a_input = %d, sum = %d (Esperado: 14)", a_input, sum);

        a_input = 32'd100; #10;
        if (sum == 32'd104)
            $display("Prueba 3 pasada: a_input = %d, sum = %d (Esperado: 104)", a_input, sum);
        else
            $display("Prueba 3 fallida: a_input = %d, sum = %d (Esperado: 104)", a_input, sum);

        a_input = 32'd4294967290; #10;
        if (sum == 32'd4294967294)
            $display("Prueba 4 pasada: a_input = %d, sum = %d (Esperado: 4294967294)", a_input, sum);
        else
            $display("Prueba 4 fallida: a_input = %d, sum = %d (Esperado: 4294967294)", a_input, sum);

        $stop;  // Detener simulación
    end
endmodule
