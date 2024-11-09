`timescale 1ns / 1ps

module tb_mpx_4to1;
    // Parámetros y señales de entrada y salida para el multiplexor
    reg  [31:0] i_a, i_b, i_c, i_d;   // Entradas de 32 bits
    reg  [1:0]  i_sel;                // Selector de 2 bits
    wire [31:0] o_out;                // Salida de 32 bits

    // Instancia del módulo mpx_2to1
    mpx_4to1 #(.NB_INPUT(32), .NB_SEL(2)) mpx (
        .i_a(i_a),
        .i_b(i_b),
        .i_c(i_c),
        .i_d(i_d),
        .i_sel(i_sel),
        .o_out(o_out)
    );

    initial begin
        i_a = 32'hAAAA_AAAA; // Patrón de ejemplo para i_a
        i_b = 32'hBBBB_BBBB; // Patrón de ejemplo para i_b
        i_c = 32'hCCCC_CCCC; // Patrón de ejemplo para i_c
        i_d = 32'hDDDD_DDDD; // Patrón de ejemplo para i_d

        i_sel = 2'b00; #10;
        if (o_out == i_a)
            $display("Prueba 1 pasada: i_sel = %b, o_out = %h (Esperado: %h)", i_sel, o_out, i_a);
        else
            $display("Prueba 1 fallida: i_sel = %b, o_out = %h (Esperado: %h)", i_sel, o_out, i_a);

        i_sel = 2'b01; #10;
        if (o_out == i_b)
            $display("Prueba 2 pasada: i_sel = %b, o_out = %h (Esperado: %h)", i_sel, o_out, i_b);
        else
            $display("Prueba 2 fallida: i_sel = %b, o_out = %h (Esperado: %h)", i_sel, o_out, i_b);

        i_sel = 2'b10; #10;
        if (o_out == i_c)
            $display("Prueba 3 pasada: i_sel = %b, o_out = %h (Esperado: %h)", i_sel, o_out, i_c);
        else
            $display("Prueba 3 fallida: i_sel = %b, o_out = %h (Esperado: %h)", i_sel, o_out, i_c);

        i_sel = 2'b11; #10;
        if (o_out == i_d)
            $display("Prueba 4 pasada: i_sel = %b, o_out = %h (Esperado: %h)", i_sel, o_out, i_d);
        else
            $display("Prueba 4 fallida: i_sel = %b, o_out = %h (Esperado: %h)", i_sel, o_out, i_d);

        $stop;  
    end
endmodule
