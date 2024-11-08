`timescale 1ns / 1ps

module tb_IF;

// Parámetros del diseño
parameter NB_REG = 32;
parameter NB_WIDHT = 9;
parameter NB_INST = 26;

// Registros de entrada
reg i_clk;
reg i_reset;
reg i_dunit_clk_en;
reg i_dunit_w_en;
reg [NB_WIDHT-1:0] i_dunit_addr;
reg i_PCSrc;
reg i_Jump;
reg i_JSel;
reg i_PCWrite;
reg [NB_REG-1:0] i_inmed;
reg [NB_INST-1:0] i_inst_to_mxp;
reg [NB_REG-1:0] i_pc_jsel;
reg [NB_REG-1:0] i_dunit_data;

// Registros de salida
wire [NB_REG-1:0] o_pcplus4;
wire [NB_REG-1:0] o_instruction;

// Instanciación del módulo IF
IF #(
    .NB_REG(NB_REG),
    .NB_WIDHT(NB_WIDHT),
    .NB_INST(NB_INST)
) u_IF (
    .i_clk(i_clk),
    .i_reset(i_reset),
    .i_dunit_clk_en(i_dunit_clk_en),
    .i_dunit_w_en(i_dunit_w_en),
    .i_dunit_addr(i_dunit_addr),
    .i_PCSrc(i_PCSrc),
    .i_Jump(i_Jump),
    .i_JSel(i_JSel),
    .i_PCWrite(i_PCWrite),
    .i_inmed(i_inmed),
    .i_inst_to_mxp(i_inst_to_mxp),
    .i_pc_jsel(i_pc_jsel),
    .i_dunit_data(i_dunit_data),
    .o_pcplus4(o_pcplus4),
    .o_instruction(o_instruction)
);

// Generador de reloj
always begin
    #5 i_clk = ~i_clk;  // Reloj de 10ns
end

// Inicialización del testbench
initial begin
    // Inicialización de señales
    i_clk = 0;
    i_reset = 0;
    i_dunit_clk_en = 1;
    i_dunit_w_en = 1;
    i_dunit_addr = 0;
    i_PCSrc = 0;
    i_Jump = 0;
    i_JSel = 0;
    i_PCWrite = 1;
    i_inmed = 32'h00000010;   // Ejemplo de inmediato
    i_inst_to_mxp = 26'b10101010101010101010101010; // Instrucción de ejemplo
    i_pc_jsel = 32'h00000000; // Valor de PC Jsel
    i_dunit_data = 32'h00000000; // Datos de ejemplo para la unidad de datos

    // Mostrar mensajes de inicio
    $display("Testbench iniciado");
    $display("PC = 0x%h, Instrucción = 0x%h", o_pcplus4, o_instruction);

    // Aplicar reset
    $display("Aplicando reset...");
    i_reset = 1;
    #10;
    i_reset = 0;
    i_PCWrite = 1;
    i_dunit_w_en = 1;

    // Esperar algunas simulaciones para ver el resultado después del reset
    // #10;
    // $display("Post-reset: PC = 0x%h, Instrucción = 0x%h", o_pcplus4, o_instruction);
    
    // // Test 1: Test de PCSrc y PCWrite
    $display("Test 1: Test de PCSrc y PCWrite");
    i_PCSrc = 1;
    i_PCWrite = 1;
    i_inmed = 32'h00000020;  // Nuevo valor para PC
    #10;
    $display("Después de PCSrc: PC = 0x%h, Instrucción = 0x%h", o_pcplus4, o_instruction);

    // Test 2: Test de Jump
    $display("Test 2: Test de Jump");
    i_PCSrc = 0;
    //i_Jump = 1;
    i_inmed = 32'h00000040;  // Nuevo valor para Jump
    #10;
    $display("Después de Jump: PC = 0x%h, Instrucción = 0x%h", o_pcplus4, o_instruction);
    
    // Test 3: Test de JSel
    $display("Test 3: Test de JSel");
    i_JSel = 1;
    i_pc_jsel = 32'h00000080;
    #10;
    $display("Después de JSel: PC = 0x%h, Instrucción = 0x%h", o_pcplus4, o_instruction);

    // Test 4: Test de lectura y escritura en memoria
    $display("Test 4: Test de lectura y escritura en memoria");
    i_PCWrite = 1;
    i_dunit_w_en = 1;
    i_JSel=0;
    i_dunit_addr = o_pcplus4;  // Dirección igual al valor de PC
    i_dunit_data = 32'hDEADBEEF;  // Datos a escribir
    #10;
    $display("Escritura en memoria: Dirección = 0x%h, Datos escritos = 0x%h", i_dunit_addr, i_dunit_data);
    
    // Test de lectura de memoria
    #10;
    $display("Lectura de memoria: Dirección = 0x%h, Datos leídos = 0x%h", i_dunit_addr, o_instruction);
    // Finalizar la simulación
    $finish;
end

endmodule
