`timescale 1ns / 1ps

module tb_pc;
    // Parámetros y señales
    parameter PC_WIDTH = 32;
    reg                i_clk;
    reg                i_reset;
    reg                i_enable;
    reg                PCWrite;
    reg  [PC_WIDTH-1:0] pc_in;
    wire [PC_WIDTH-1:0] pc_out;

    // Instanciación del módulo pc
    pc #(.PC_WIDTH(PC_WIDTH)) uut (
        .i_clk(i_clk),
        .i_reset(i_reset),
        .i_enable(i_enable),
        .PCWrite(PCWrite),
        .pc_in(pc_in),
        .pc_out(pc_out)
    );

    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;  // Reloj de 10ns
    end

    initial begin

        i_reset = 1;
        i_enable = 0;
        PCWrite = 0;
        pc_in = 32'd100;

        #10 i_reset = 0;           // Quitar reset
        #10;
        
        if (pc_out == 32'd0)
            $display("Test 1: Reset aplicado correctamente, pc_out = %d (Esperado: 0)", pc_out);
        else
            $display("Test 1 FALLÓ: Reset incorrecto, pc_out = %d (Esperado: 0)", pc_out);

        // Prueba sin habilitar (i_enable = 0)
        i_enable = 0;
        pc_in = 32'd200;
        PCWrite = 1;
        #10;
        if (pc_out == 32'd0)
            $display("Test 2: i_enable desactivado, pc_out mantiene valor = %d (Esperado: 0)", pc_out);
        else
            $display("Test 2 FALLÓ: i_enable desactivado, pc_out incorrecto = %d (Esperado: 0)", pc_out);

        i_enable = 1;
        PCWrite = 0;
        pc_in = 32'd300;
        #10;
        if (pc_out == 32'd0)
            $display("Test 3: PCWrite inactivo, pc_out mantiene valor = %d (Esperado: 0)", pc_out);
        else
            $display("Test 3 FALLÓ: PCWrite inactivo, pc_out incorrecto = %d (Esperado: 0)", pc_out);

        PCWrite = 1;
        pc_in = 32'd400;
        #10;
        if (pc_out == 32'd400)
            $display("Test 4: PC actualizado correctamente, pc_out = %d (Esperado: 400)", pc_out);
        else
            $display("Test 4 FALLÓ: PC no se actualizó correctamente, pc_out = %d (Esperado: 400)", pc_out);

        i_enable = 0;
        pc_in = 32'd500;
        #10;
        if (pc_out == 32'd400)
            $display("Test 5: i_enable desactivado, pc_out mantiene valor = %d (Esperado: 400)", pc_out);
        else
            $display("Test 5 FALLÓ: i_enable desactivado, pc_out incorrecto = %d (Esperado: 400)", pc_out);

        i_reset = 1;
        #10;
        i_reset = 0;
        #10;
        PCWrite =1;
        i_enable=1;
        if (pc_out == 32'd0)
            $display("Test 6: Reset final aplicado correctamente, pc_out = %d (Esperado: 0)", pc_out);
        else
            $display("Test 6 FALLÓ: Reset final incorrecto, pc_out = %d (Esperado: 0)", pc_out);

        $stop; // Detener simulación
    end
endmodule
