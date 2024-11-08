`timescale 1ns / 1ps

module tb_dist_mem_gen_0;

  // Definición de señales
  reg [9:0] a;        // Dirección de memoria
  reg [31:0] d;       // Datos de entrada
  reg clk;            // Señal de reloj
  reg we;             // Señal de escritura
  reg i_ce;           // Clock enable
  wire [31:0] spo;    // Datos de salida

  // Instancia de la memoria
  dist_mem_gen_0 uut (
    .a(a),
    .d(d),
    .clk(clk),
    .we(we),
    .i_ce(i_ce),
    .spo(spo)
  );

  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Periodo de 10 ns
  end

  initial begin
    we = 0;
    i_ce = 0; // Inicialmente, clock enable desactivado
    a = 10'b0;
    d = 32'h0;
    #15; // Esperar 10 ns

    // Activar clock enable y realizar escrituras
    i_ce = 1;

    // Escritura en la dirección 0
    a = 10'b0000000000;
    d = 32'hAAAA_BBBB;
    we = 1; // Habilitar escritura
    #10; // Esperar un ciclo de reloj

    // Escritura en la dirección 1
    a = 10'b0000000001;
    d = 32'hCCCC_DDDD;
    #10;

    // Escritura en la dirección 2
    a = 10'b0000000010;
    d = 32'hEEEE_FFFF;
    #10;

    // Deshabilitar escritura y clock enable
    we = 0;
    //i_ce = 0; // Desactivar clock enable para pruebas adicionales
    #10;

    // Activar clock enable para lecturas
    i_ce = 1;

    // Lectura desde la dirección 0
    #5; // Esperar un ciclo de reloj para lectura
    a = 10'b0000000000;
    #5;
    $display("Lectura dirección 0: %h (esperado: AAAA_BBBB)", spo);

    #5;
    a = 10'b0000000001;
    #5;
    $display("Lectura dirección 1: %h (esperado: CCCC_DDDD)", spo);

    // Lectura desde la dirección 2
    #5;
    a = 10'b0000000010;
    #5;
    $display("Lectura dirección 2: %h (esperado: EEEE_FFFF)", spo);

    // Fin de la simulación
    $stop;
  end

endmodule
